import os
import base64
from typing import Optional, Dict

import httpx

TAG = __name__


class DeviceNotFoundException(Exception):
    pass


class DeviceBindException(Exception):
    def __init__(self, bind_code):
        self.bind_code = bind_code
        super().__init__(f"Device binding error, binding code: {bind_code}")


class ManageApiClient:
    _instance = None
    _async_clients = {}  # For storing separate clients for each event loop
    _secret = None

    def __new__(cls, config):
        """Singleton pattern to ensure a globally unique instance and support passing configuration parameters"""
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._init_client(config)
        return cls._instance

    @classmethod
    def _init_client(cls, config):
        """Initialize configuration (deferred client creation)"""
        cls.config = config.get("manager-api")

        if not cls.config:
            raise Exception("manager-api configuration error")
        if not cls.config.get("url") or not cls.config.get("secret"):
            raise Exception("manager-api url or secret configuration error")

        if "you" in cls.config.get("secret") or "你" in cls.config.get("secret"):  # default placeholder check
            raise Exception("Please configure the manager-api secret first")

        cls._secret = cls.config.get("secret")
        cls.max_retries = cls.config.get("max_retries", 6)  # Maximum retry attempts
        cls.retry_delay = cls.config.get("retry_delay", 10)  # Initial retry delay (seconds)
        # Do not create AsyncClient here, delay until actual use
        cls._async_clients = {}

    @classmethod
    async def _ensure_async_client(cls):
        """Ensure the asynchronous client is created (create separate clients for each event loop)"""
        import asyncio

        try:
            loop = asyncio.get_running_loop()
            loop_id = id(loop)

            # Create separate clients for each event loop
            if loop_id not in cls._async_clients:
                # The server may actively close connections, and httpx connection pool cannot correctly detect and clean up
                limits = httpx.Limits(
                    max_keepalive_connections=0,  # Disable keep-alive, create a new connection each time
                )
                cls._async_clients[loop_id] = httpx.AsyncClient(
                    base_url=cls.config.get("url"),
                    headers={
                        "User-Agent": f"PythonClient/2.0 (PID:{os.getpid()})",
                        "Accept": "application/json",
                        "Authorization": "Bearer " + cls._secret,
                    },
                    timeout=cls.config.get("timeout", 30),
                    limits=limits,  # Usage restrictions
                )
            return cls._async_clients[loop_id]
        except RuntimeError:
            # If there is no running event loop, create a temporary one
            raise Exception("Must be called within an asynchronous context")

    @classmethod
    async def _async_request(cls, method: str, endpoint: str, **kwargs) -> Dict:
        """Send a single asynchronous HTTP request and handle the response"""
        # Ensure the client is created
        client = await cls._ensure_async_client()
        endpoint = endpoint.lstrip("/")
        response = None
        try:
            response = await client.request(method, endpoint, **kwargs)
            response.raise_for_status()

            result = response.json()

            # Handle business errors returned by the API
            if result.get("code") == 10041:
                raise DeviceNotFoundException(result.get("msg"))
            elif result.get("code") == 10042:
                raise DeviceBindException(result.get("msg"))
            elif result.get("code") != 0:
                raise Exception(f"API returned error: {result.get('msg', 'Unknown error')}")

            # Return successful data
            return result.get("data") if result.get("code") == 0 else None
        finally:
            # Ensure the response is closed (executed even if an exception occurs)
            if response is not None:
                await response.aclose()

    @classmethod
    def _should_retry(cls, exception: Exception) -> bool:
        """Determine if an exception should trigger a retry"""
        # Network-related errors
        if isinstance(
            exception, (httpx.ConnectError, httpx.TimeoutException, httpx.NetworkError)
        ):
            return True

        # HTTP status code errors
        if isinstance(exception, httpx.HTTPStatusError):
            status_code = exception.response.status_code
            return status_code in [408, 429, 500, 502, 503, 504]

        return False

    @classmethod
    async def _execute_async_request(cls, method: str, endpoint: str, **kwargs) -> Dict:
        """Asynchronous request executor with retry mechanism"""
        import asyncio

        retry_count = 0

        while retry_count <= cls.max_retries:
            try:
                # Execute asynchronous request
                return await cls._async_request(method, endpoint, **kwargs)
            except Exception as e:
                # Determine if should retry
                if retry_count < cls.max_retries and cls._should_retry(e):
                    retry_count += 1
                    print(
                        f"{method} {endpoint} 异步请求失败，将在 {cls.retry_delay:.1f} 秒后进行第 {retry_count} 次重试"
                    )
                    await asyncio.sleep(cls.retry_delay)
                    continue
                else:
                    # Do not retry, raise the exception directly
                    raise

    @classmethod
    def safe_close(cls):
        """Safely close all asynchronous connection pools"""
        import asyncio

        for client in list(cls._async_clients.values()):
            try:
                asyncio.run(client.aclose())
            except Exception:
                pass
        cls._async_clients.clear()
        cls._instance = None


async def get_server_config() -> Optional[Dict]:
    """Get server base configuration"""
    return await ManageApiClient._instance._execute_async_request(
        "POST", "/config/server-base"
    )


async def get_agent_models(
    mac_address: str, client_id: str, selected_module: Dict
) -> Optional[Dict]:
    """Get agent model configuration"""
    return await ManageApiClient._instance._execute_async_request(
        "POST",
        "/config/agent-models",
        json={
            "macAddress": mac_address,
            "clientId": client_id,
            "selectedModule": selected_module,
        },
    )


async def generate_and_save_chat_summary(session_id: str) -> Optional[Dict]:
    """Generate and save chat summary"""
    try:
        return await ManageApiClient._instance._execute_async_request(
            "POST",
            f"/agent/chat-summary/{session_id}/save",
        )
    except Exception as e:
        print(f"Failed to generate and save chat summary: {e}")
        return None


async def report(
    mac_address: str, session_id: str, chat_type: int, content: str, audio, report_time
) -> Optional[Dict]:
    """Asynchronous chat record reporting"""
    if not content or not ManageApiClient._instance:
        return None
    try:
        return await ManageApiClient._instance._execute_async_request(
            "POST",
            f"/agent/chat-history/report",
            json={
                "macAddress": mac_address,
                "sessionId": session_id,
                "chatType": chat_type,
                "content": content,
                "reportTime": report_time,
                "audioBase64": (
                    base64.b64encode(audio).decode("utf-8") if audio else None
                ),
            },
        )
    except Exception as e:
        print(f"Failed to report TTS: {e}")
        return None


def init_service(config):
    ManageApiClient(config)


def manage_api_http_safe_close():
    ManageApiClient.safe_close()
