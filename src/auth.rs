//! Auth implementation for bore client and server.

use anyhow::{bail, ensure, Result};
use hmac::{Hmac, Mac};
use sha2::{Digest, Sha256};
use tokio::io::{AsyncRead, AsyncWrite};
use uuid::Uuid;
use serde::{Deserialize, Serialize};

use crate::shared::{ClientMessage, Delimited, ServerMessage};

/// Wrapper around a MAC used for authenticating clients that have a secret.
pub struct Authenticator(Hmac<Sha256>);

impl Authenticator {
    /// Generate an authenticator from a secret.
    pub fn new(secret: &str) -> Self {
        let hashed_secret = Sha256::new().chain_update(secret).finalize();
        Self(Hmac::new_from_slice(&hashed_secret).expect("HMAC can take key of any size"))
    }

    /// Generate a reply message for a challenge.
    pub fn answer(&self, challenge: &Uuid) -> String {
        let mut hmac = self.0.clone();
        hmac.update(challenge.as_bytes());
        hex::encode(hmac.finalize().into_bytes())
    }

    /// Validate a reply to a challenge.
    ///
    /// ```
    /// use bore_cli::auth::Authenticator;
    /// use uuid::Uuid;
    ///
    /// let auth = Authenticator::new("secret");
    /// let challenge = Uuid::new_v4();
    ///
    /// assert!(auth.validate(&challenge, &auth.answer(&challenge)));
    /// assert!(!auth.validate(&challenge, "wrong answer"));
    /// ```
    pub fn validate(&self, challenge: &Uuid, tag: &str) -> bool {
        if let Ok(tag) = hex::decode(tag) {
            let mut hmac = self.0.clone();
            hmac.update(challenge.as_bytes());
            hmac.verify_slice(&tag).is_ok()
        } else {
            false
        }
    }

    /// As the server, send a challenge to the client and validate their response.
    pub async fn server_handshake<T: AsyncRead + AsyncWrite + Unpin>(
        &self,
        stream: &mut Delimited<T>,
    ) -> Result<()> {
        let challenge = Uuid::new_v4();
        stream.send(ServerMessage::Challenge(challenge)).await?;
        match stream.recv_timeout().await? {
            Some(ClientMessage::Authenticate(tag)) => {
                ensure!(self.validate(&challenge, &tag), "invalid secret");
                Ok(())
            }
            _ => bail!("server requires secret, but no secret was provided"),
        }
    }

    /// As the client, answer a challenge to attempt to authenticate with the server.
    pub async fn client_handshake<T: AsyncRead + AsyncWrite + Unpin>(
        &self,
        stream: &mut Delimited<T>,
    ) -> Result<()> {
        let challenge = match stream.recv_timeout().await? {
            Some(ServerMessage::Challenge(challenge)) => challenge,
            _ => bail!("expected authentication challenge, but no secret was required"),
        };
        let tag = self.answer(&challenge);
        stream.send(ClientMessage::Authenticate(tag)).await?;
        Ok(())
    }
}

/// API Key Authenticator that validates against NativeBridge backend
pub struct ApiKeyAuthenticator {
    validation_url: String,
    client: reqwest::Client,
}

#[derive(Serialize)]
struct ValidationRequest {
    api_key: String,
}

#[derive(Deserialize)]
struct ValidationResponse {
    valid: bool,
    #[serde(default)]
    user_id: Option<String>,
    #[serde(default)]
    error: Option<String>,
}

impl ApiKeyAuthenticator {
    /// Create a new API key authenticator with the validation URL
    pub fn new(validation_url: String) -> Self {
        Self {
            validation_url,
            client: reqwest::Client::builder()
                .timeout(std::time::Duration::from_secs(5))
                .build()
                .expect("failed to create HTTP client"),
        }
    }

    /// Validate an API key against the backend
    async fn validate_api_key(&self, api_key: &str) -> Result<bool> {
        let response = self
            .client
            .post(&self.validation_url)
            .header("Authorization", format!("Bearer {}", api_key))
            .json(&ValidationRequest {
                api_key: api_key.to_string(),
            })
            .send()
            .await?;

        if response.status().is_success() {
            let validation: ValidationResponse = response.json().await?;
            Ok(validation.valid)
        } else {
            Ok(false)
        }
    }

    /// Server-side handshake: receive API key and validate it
    pub async fn server_handshake<T: AsyncRead + AsyncWrite + Unpin>(
        &self,
        stream: &mut Delimited<T>,
    ) -> Result<()> {
        let challenge = Uuid::new_v4();
        stream.send(ServerMessage::Challenge(challenge)).await?;

        match stream.recv_timeout().await? {
            Some(ClientMessage::Authenticate(api_key)) => {
                // Validate API key with backend
                let is_valid = self.validate_api_key(&api_key).await
                    .unwrap_or(false);

                ensure!(is_valid, "invalid API key");
                Ok(())
            }
            _ => bail!("server requires API key authentication"),
        }
    }

    /// Client-side handshake: send API key for validation
    pub async fn client_handshake<T: AsyncRead + AsyncWrite + Unpin>(
        api_key: &str,
        stream: &mut Delimited<T>,
    ) -> Result<()> {
        match stream.recv_timeout().await? {
            Some(ServerMessage::Challenge(_)) => {
                // Send API key instead of HMAC
                stream.send(ClientMessage::Authenticate(api_key.to_string())).await?;
                Ok(())
            }
            _ => bail!("expected authentication challenge"),
        }
    }
}
