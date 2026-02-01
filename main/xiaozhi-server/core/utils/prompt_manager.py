"""
The System Prompt Manager module is responsible for managing 
and updating system prompts, including quick initialization 
and asynchronous enhancements.
"""

import os
from typing import Dict, Any
from config.logger import setup_logging
from jinja2 import Template

TAG = __name__

# Map original English weekdays to current language weekday names
WEEKDAY_MAP = {
    "Monday": "Monday",
    "Tuesday": "Tuesday", 
    "Wednesday": "Wednesday",
    "Thursday": "Thursday",
    "Friday": "Friday",
    "Saturday": "Saturday",
    "Sunday": "Sunday",
}

EMOJI_List = [
    "😶",
    "🙂",
    "😆",
    "😂",
    "😔",
    "😠",
    "😭",
    "😍",
    "😳",
    "😲",
    "😱",
    "🤔",
    "😉",
    "😎",
    "😌",
    "🤤",
    "😘",
    "😏",
    "😴",
    "😜",
    "🙄",
]


class PromptManager:
    """System Prompt Manager responsible for managing and updating system prompts"""

    def __init__(self, config: Dict[str, Any], logger=None):
        self.config = config
        self.logger = logger or setup_logging()
        self.base_prompt_template = None
        self.last_update_time = 0

        # Import Global Cache Manager
        from core.utils.cache.manager import cache_manager, CacheType

        self.cache_manager = cache_manager
        self.CacheType = CacheType
        
        # Initialize context source
        from core.utils.context_provider import ContextDataProvider
        self.context_provider = ContextDataProvider(config, self.logger)
        self.context_data = {}

        self._load_base_template()

    def _load_base_template(self):
        """Load base prompt template"""
        try:
            template_path = self.config.get("prompt_template", None)
            if not template_path:
                template_path = "agent-base-prompt.txt"
            cache_key = f"prompt_template:{template_path}"

            # First, try to get from cache
            cached_template = self.cache_manager.get(self.CacheType.CONFIG, cache_key)
            if cached_template is not None:
                self.base_prompt_template = cached_template
                self.logger.bind(tag=TAG).debug("Loaded base prompt template from cache")
                return

            # Cache miss, read from file
            if os.path.exists(template_path):
                with open(template_path, "r", encoding="utf-8") as f:
                    template_content = f.read()

                # Cache the template (CONFIG type does not expire automatically, manual invalidation required)
                self.cache_manager.set(
                    self.CacheType.CONFIG, cache_key, template_content
                )
                self.base_prompt_template = template_content
                self.logger.bind(tag=TAG).debug("Successfully loaded base prompt template and cached it")
            else:
                self.logger.bind(tag=TAG).warning(f"File not found: {template_path}")
        except Exception as e:
            self.logger.bind(tag=TAG).error(f"Failed to load prompt template: {e}")
    def get_quick_prompt(self, user_prompt: str, device_id: str = None) -> str:
        """Quickly get system prompt (using user configuration)"""
        device_cache_key = f"device_prompt:{device_id}"
        cached_device_prompt = self.cache_manager.get(
            self.CacheType.DEVICE_PROMPT, device_cache_key
        )
        if cached_device_prompt is not None:
            self.logger.bind(tag=TAG).debug(f"Using cached prompt for device {device_id}")
            return cached_device_prompt
        else:
            self.logger.bind(tag=TAG).debug(
                f"No cached prompt for device {device_id}, using provided prompt"
            )

        # Use the provided prompt and cache it (if device ID is available)
        if device_id:
            device_cache_key = f"device_prompt:{device_id}"
            self.cache_manager.set(self.CacheType.CONFIG, device_cache_key, user_prompt)
            self.logger.bind(tag=TAG).debug(f"Prompt for device {device_id} has been cached")
        self.logger.bind(tag=TAG).info(f"Using quick prompt: {user_prompt[:50]}...")
        return user_prompt

    def _get_current_time_info(self) -> tuple:
        """Get current time information"""
        from .current_time import (
            get_current_date,
            get_current_weekday,
            get_current_lunar_date,
        )

        today_date = get_current_date()
        today_weekday = get_current_weekday()
        lunar_date = get_current_lunar_date() + "\n"

        return today_date, today_weekday, lunar_date

    def _get_location_info(self, client_ip: str) -> str:
        """Get location information"""
        try:
            # First, try to get from cache
            cached_location = self.cache_manager.get(self.CacheType.LOCATION, client_ip)
            if cached_location is not None:
                return cached_location

            # Cache miss, call API to get
            from core.utils.util import get_ip_info

            ip_info = get_ip_info(client_ip, self.logger)
            city = ip_info.get("city", "Unknown location")
            location = f"{city}"

            # Cache it
            self.cache_manager.set(self.CacheType.LOCATION, client_ip, location)
            return location
        except Exception as e:
            self.logger.bind(tag=TAG).error(f"Failed to get location information: {e}")
            return "Unknown location"

    def _get_weather_info(self, conn, location: str) -> str:
        """Get weather information"""
        try:
            # First, try to get from cache
            cached_weather = self.cache_manager.get(self.CacheType.WEATHER, location)
            if cached_weather is not None:
                return cached_weather

            # Cache miss, call get_weather function to get
            from plugins_func.functions.get_weather import get_weather
            from plugins_func.register import ActionResponse

            # Call get_weather function
            result = get_weather(conn, location=location, lang="zh_CN")
            if isinstance(result, ActionResponse):
                weather_report = result.result
                self.cache_manager.set(self.CacheType.WEATHER, location, weather_report)
                return weather_report
            return "Failed to get weather information"

        except Exception as e:
            self.logger.bind(tag=TAG).error(f"Failed to get weather information: {e}")
            return "Failed to get weather information"
    def update_context_info(self, conn, client_ip: str):
        """Synchronously update context information"""
        try:
            local_address = ""
            if (
                client_ip
                and self.base_prompt_template
                and (
                    "local_address" in self.base_prompt_template
                    or "weather_info" in self.base_prompt_template
                )
            ):
                # Get location information (using global cache)
                local_address = self._get_location_info(client_ip)

            if (
                self.base_prompt_template
                and "weather_info" in self.base_prompt_template
                and local_address
            ):
                # Get weather information (using global cache)
                self._get_weather_info(conn, local_address)
            
            # Get configured context data
            if hasattr(conn, "device_id") and conn.device_id:
                if self.base_prompt_template and "dynamic_context" in self.base_prompt_template:
                    self.context_data = self.context_provider.fetch_all(conn.device_id)
                else:
                    self.context_data = ""
                
            self.logger.bind(tag=TAG).debug(f"Context information updated")

        except Exception as e:
            self.logger.bind(tag=TAG).error(f"Failed to update context information: {e}")

    def build_enhanced_prompt(
        self, user_prompt: str, device_id: str, client_ip: str = None, *args, **kwargs
    ) -> str:
        """Build enhanced system prompt"""
        if not self.base_prompt_template:
            return user_prompt

        try:
            # Get the latest time information (not cached)
            today_date, today_weekday, lunar_date = self._get_current_time_info()

            # Get cached context information
            local_address = ""
            weather_info = ""

            if client_ip:
                # Get location information (from global cache)
                local_address = (
                    self.cache_manager.get(self.CacheType.LOCATION, client_ip) or ""
                )

                # Get weather information (from global cache)
                if local_address:
                    weather_info = (
                        self.cache_manager.get(self.CacheType.WEATHER, local_address)
                        or ""
                    )

            # Replace template variables
            template = Template(self.base_prompt_template)
            enhanced_prompt = template.render(
                base_prompt=user_prompt,
                current_time="{{current_time}}",
                today_date=today_date,
                today_weekday=today_weekday,
                lunar_date=lunar_date,
                local_address=local_address,
                weather_info=weather_info,
                emojiList=EMOJI_List,
                device_id=device_id,
                client_ip=client_ip,
                dynamic_context=self.context_data,
                *args,
                **kwargs,
            )
            device_cache_key = f"device_prompt:{device_id}"
            self.cache_manager.set(
                self.CacheType.DEVICE_PROMPT, device_cache_key, enhanced_prompt
            )
            self.logger.bind(tag=TAG).info(
                f"Successfully built enhanced prompt, length: {len(enhanced_prompt)}"
            )
            return enhanced_prompt

        except Exception as e:
            self.logger.bind(tag=TAG).error(f"Failed to build enhanced prompt: {e}")
            return user_prompt
