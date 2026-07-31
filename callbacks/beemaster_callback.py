"""
Beemaster Credit Deduction Callback for LiteLLM

This callback is triggered after each successful LLM request.
It deducts credits from the user's balance via the Supabase Edge Function
consume-credit.

Environment Variables:
- SUPABASE_URL: URL of the Supabase project
- INTERNAL_API_KEY: Secret key for Edge Function authentication
"""

import os
import requests
import logging

logger = logging.getLogger(__name__)

SUPABASE_URL = os.getenv("SUPABASE_URL", "")
INTERNAL_API_KEY = os.getenv("INTERNAL_API_KEY", "")


def beemaster_credits_callback(kwargs):
    """
    Called after each successful LLM request.

    Deducts credits from the user's balance based on token usage.
    Formula: credits = max(1, total_tokens // 1000)

    Args:
        kwargs: LiteLLM callback kwargs containing:
            - user: The user_id (from Custom Auth)
            - usage: Token usage dict with total_tokens
            - model: The model used

    Returns:
        dict: Response from Supabase consume-credit
    """
    try:
        # Extract user_id from Custom Auth metadata
        user_id = kwargs.get("user", "unknown")

        # Get token usage
        usage = kwargs.get("usage", {})
        total_tokens = usage.get("total_tokens", 0)
        prompt_tokens = usage.get("prompt_tokens", 0)
        completion_tokens = usage.get("completion_tokens", 0)

        # Calculate credits (1 credit per 1000 tokens, minimum 1)
        credits = max(1, total_tokens // 1000)

        # Build description
        model = kwargs.get("model", "unknown")
        description = f"LLM Query: {model} ({total_tokens} tokens: {prompt_tokens} prompt + {completion_tokens} completion)"

        logger.info(f"Deducting {credits} credits for user {user_id}")

        # Call Supabase consume-credit Edge Function
        # Note: The user's JWT is passed through from the original request
        # via kwargs.get("litellm_params", {}).get("metadata", {})
        # For server-side deduction, we use the internal API key

        # Get the original API key (JWT) from kwargs
        api_key = kwargs.get("litelllm_params", {}).get("api_key", "")
        if not api_key:
            # Fallback: try to get from kwargs directly
            api_key = kwargs.get("api_key", "")

        if not api_key or not SUPABASE_URL:
            logger.error("Missing API key or SUPABASE_URL for credit deduction")
            return {"error": "Configuration missing"}

        response = requests.post(
            f"{SUPABASE_URL}/functions/v1/consume-credit",
            headers={
                "Authorization": f"Bearer {api_key}",
                "apikey": INTERNAL_API_KEY,
                "Content-Type": "application/json",
            },
            timeout=10,
        )

        if response.status_code == 200:
            result = response.json()
            logger.info(f"Credits deducted: {result}")
            return result
        else:
            logger.error(f"Failed to deduct credits: {response.status_code} - {response.text}")
            return {"error": response.text}

    except Exception as e:
        logger.error(f"Beemaster callback error: {str(e)}")
        return {"error": str(e)}


# LiteLLM callback registration
async def async_success_callback(kwargs):
    """Async wrapper for the success callback."""
    return beemaster_credits_callback(kwargs)
