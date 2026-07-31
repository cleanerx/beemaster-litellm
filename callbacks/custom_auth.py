"""
Beemaster Custom Auth for LiteLLM

This module provides custom authentication for LiteLLM by validating
Supabase JWT tokens against the Supabase Edge Function verify-litellm-key.

When a request comes to LiteLLM with Authorization: Bearer <supabaseJWT>,
LiteLLM calls user_api_key_auth() which:
1. Sends the JWT to Supabase verify-litellm-key Edge Function
2. If valid, returns UserAPIKeyAuth object (request proceeds)
3. If invalid, raises Exception (request rejected)

Environment Variables:
- SUPABASE_URL: Supabase project URL (e.g., https://xxx.supabase.co)
- INTERNAL_API_KEY: Secret key for Edge Function authentication

See: beemaster-android/docs/04_adr/ADR-021_supabase_pi5_litellm_hybrid.md
"""

import os
import requests
import logging
from typing import Union
from fastapi import Request
from litellm.proxy._types import UserAPIKeyAuth

logger = logging.getLogger(__name__)

SUPABASE_URL = os.getenv("SUPABASE_URL", "")
INTERNAL_API_KEY = os.getenv("INTERNAL_API_KEY", "")


async def user_api_key_auth(request: Request, api_key: str) -> Union[UserAPIKeyAuth, str]:
    """
    Custom auth function for LiteLLM.

    Called by LiteLLM on every request to validate the API key.
    In our case, the "API key" is a Supabase JWT.

    Args:
        request: The FastAPI request object
        api_key: The bearer token (Supabase JWT)

    Returns:
        UserAPIKeyAuth object if valid

    Raises:
        Exception if invalid
    """
    try:
        if not api_key:
            raise Exception("No API key provided")

        if not SUPABASE_URL:
            raise Exception("SUPABASE_URL not configured")

        if not INTERNAL_API_KEY:
            raise Exception("INTERNAL_API_KEY not configured")

        # Call Supabase Edge Function to validate JWT
        response = requests.post(
            f"{SUPABASE_URL}/functions/v1/verify-litellm-key",
            headers={
                "X-Internal-Key": INTERNAL_API_KEY,
                "Content-Type": "application/json",
            },
            json={"key": api_key},
            timeout=10,
        )

        if response.status_code != 200:
            logger.error(f"Supabase auth failed: {response.status_code} - {response.text}")
            raise Exception(f"Authentication failed: {response.status_code}")

        result = response.json()

        if not result.get("valid"):
            error = result.get("error", "Unknown error")
            logger.error(f"Supabase auth rejected: {error}")
            raise Exception(f"Invalid credentials: {error}")

        user_id = result.get("user_id", "unknown")
        credits_balance = result.get("metadata", {}).get("credits_balance", 0)

        logger.info(f"Authenticated user {user_id}, credits: {credits_balance}")

        # Return UserAPIKeyAuth — LiteLLM uses this for spend tracking
        return UserAPIKeyAuth(
            api_key=api_key,
            user_id=user_id,
            metadata={"credits_balance": credits_balance},
        )

    except requests.RequestException as e:
        logger.error(f"Failed to call Supabase verify-litellm-key: {str(e)}")
        raise Exception(f"Auth service unavailable: {str(e)}")
    except Exception as e:
        logger.error(f"Custom auth error: {str(e)}")
        raise
