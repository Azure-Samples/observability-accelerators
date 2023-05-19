#!/usr/bin/env python
"""Defines the applications processing loop
"""

import asyncio
from app_context import ApplicationContext

if __name__ == "__main__":
    application_context = ApplicationContext()

    loop = asyncio.get_event_loop()
    loop.run_until_complete(application_context.start())
