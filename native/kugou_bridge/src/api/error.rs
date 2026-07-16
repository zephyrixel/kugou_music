use kugou_sdk::KugouError;

use super::dto::{BridgeError, BridgeErrorKind};

impl BridgeError {
    pub(super) fn invalid_argument(message: impl Into<String>) -> Self {
        Self {
            kind: BridgeErrorKind::InvalidArgument,
            message: message.into(),
            code: None,
            retryable: false,
        }
    }

    pub(super) fn internal(message: impl Into<String>) -> Self {
        Self {
            kind: BridgeErrorKind::Internal,
            message: message.into(),
            code: None,
            retryable: false,
        }
    }

    pub(super) fn from_sdk(error: KugouError) -> Self {
        let message = error.to_string();
        match error {
            KugouError::InvalidArgument(_) => Self::invalid_argument(message),
            KugouError::AuthenticationRequired => Self {
                kind: BridgeErrorKind::AuthenticationRequired,
                message,
                code: None,
                retryable: false,
            },
            KugouError::Transport(_) => Self {
                kind: BridgeErrorKind::Transport,
                message,
                code: None,
                retryable: true,
            },
            KugouError::Http { status: 404, .. } => Self {
                kind: BridgeErrorKind::Unsupported,
                message,
                code: Some(404),
                retryable: false,
            },
            KugouError::Http { status, .. } => Self {
                kind: BridgeErrorKind::Upstream,
                message,
                code: Some(i64::from(status)),
                retryable: status >= 500,
            },
            KugouError::Business { code, .. } if code == 20017 || code == 20018 => Self {
                kind: BridgeErrorKind::AuthenticationExpired,
                message,
                code: Some(code),
                retryable: false,
            },
            KugouError::Business { code, .. } => Self {
                kind: BridgeErrorKind::Upstream,
                message,
                code: Some(code),
                retryable: false,
            },
            KugouError::SecurityChallenge(challenge) => Self {
                kind: BridgeErrorKind::SecurityChallenge,
                message,
                code: challenge.code.parse().ok(),
                retryable: true,
            },
            _ => Self::internal(message),
        }
    }
}
