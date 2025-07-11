"""
VISA Package - PyVISA wrapper for instrument communication

This package wraps pyvisa into a class with Open/Close/Query/Write functionality
for unified management, enabling/printing control, and connection pooling.
"""

from . import Setting
import pyvisa
from typing import List, Tuple, Optional, Union
import time

"""
VISA Operations Overview:

Components:
- VISA Class: Core functionality (Open/Close/Find/List/Query)
- Query variants: Standard Query, Binary Query, Read/Write Query
- Independent Settings (referencing global variables)

Variables:
- Setting: Global configuration (Enable/Print flags)
- Connection storage: [VISA Resource, Name] pairs

Operating Principles:
1. Persistent connections - retry on failure, error on re-open failure
2. Connection pooling - avoid duplicate connections to same resource
3. Comprehensive error reporting
"""

# Global connection registry: (address, VISA_resource)
# Checked before opening new connections, removed on close
opened_connections: List[Tuple[str,
                               pyvisa.resources.MessageBasedResource]] = []

# Legacy alias for backward compatibility
Opened_List = opened_connections


class VISA:
    """
    VISA instrument communication class.

    Provides a high-level interface for VISA instrument communication with
    connection management, error handling, and debug capabilities.
    """

    def __init__(self, name: str, address: str):
        """
        Initialize VISA instrument instance.

        Args:
            name: Instrument identifier for logging and debugging
            address: VISA resource address (e.g., 'USB0::0x1234::0x5678::INSTR')
        """
        self.name = name
        self.address = address
        self.handle: Optional[Union[pyvisa.resources.MessageBasedResource,
                                    pyvisa.resources.Resource]] = None

        # Automatically open connection on initialization
        self.open()

    def open(self) -> None:
        """
        Open VISA connection if not already open.

        Checks the global connection registry to avoid duplicate connections.
        If the same address is already open, reuses the existing handle.

        Raises:
            Exception: If unable to open VISA connection after retries
        """
        global opened_connections

        # Debug output if enabled
        if Setting.VISA_Print_Enable:
            print(f"Open VISA: {self.name}")

        # Skip actual connection if VISA is disabled
        if not Setting.VISA_Send_Enable:
            return

        # Check if connection already exists for this address
        for address, handle in opened_connections:
            if address == self.address:
                self.handle = handle
                return

        try:
            # Attempt to open communication with retry logic
            retry_max = 2
            self.handle = None

            for attempt in range(retry_max):
                try:
                    resource_manager = pyvisa.ResourceManager()
                    self.handle = resource_manager.open_resource(self.address)
                    if hasattr(self.handle, 'clear'):
                        self.handle.clear()
                    time.sleep(0.5)
                    break  # Success, exit retry loop
                except Exception:
                    time.sleep(1)
                    if attempt == retry_max - 1:  # Last attempt failed
                        raise

            if self.handle is None:
                raise Exception(
                    f"VISA Open Error: {self.name}, address: {self.address}")

            # Add to connection registry if it's a message-based resource
            if isinstance(self.handle, pyvisa.resources.MessageBasedResource):
                opened_connections.append((self.address, self.handle))

        except Exception:
            # Fatal error - unable to open instrument communication
            raise Exception(
                f"VISA Open Error: {self.name}, address: {self.address}")

    def close(self) -> None:
        """
        Close VISA connection and remove from connection registry.
        """
        global opened_connections

        # Debug output if enabled
        if Setting.VISA_Print_Enable:
            print(f"Close VISA: {self.name}")

        # Skip actual closure if VISA is disabled
        if not Setting.VISA_Send_Enable:
            return

        # Close handle if it's a valid message-based resource
        if isinstance(self.handle, pyvisa.resources.MessageBasedResource):
            try:
                self.handle.close()
            except Exception:
                pass  # Ignore errors during close

            # Remove from connection registry
            opened_connections[:] = [
                (addr, handle) for addr, handle in opened_connections
                if handle != self.handle
            ]

            # Clear the handle reference
            self.handle = None

    def query(self, command: str, delay_time: Optional[float] = None) -> str:
        """
        Send a command and read the response.

        Args:
            command: SCPI command string to send
            delay_time: Optional delay before reading response (seconds)

        Returns:
            Response string from the instrument

        Raises:
            Exception: If handle is not a valid MessageBasedResource
            Exception: If communication error occurs
        """
        # Debug output if enabled
        if Setting.VISA_Print_Enable:
            print(f"[{self.name}] Query: {command}")

        # Return dummy response if VISA is disabled
        if not Setting.VISA_Send_Enable:
            return "0"

        # Ensure we have a valid message-based resource
        if isinstance(self.handle, pyvisa.resources.MessageBasedResource):
            try:
                # Send command and read response
                response = self.handle.query(command, delay_time)

                # Debug output if enabled
                if Setting.VISA_Print_Enable:
                    print(f"[{self.name}] Recv: {response}")

                return response

            except Exception:
                # Communication error occurred
                print(f"VISA Query Error: {self.name}")
                print(f"Address: {self.address}")
                print(f"Command: {command}")
                raise Exception("VISA Query Error")
        else:
            # Invalid handle state
            raise Exception("not MessageBasedResource")

    def write(self, command: str) -> None:
        """
        Send a command to the instrument.

        Args:
            command: SCPI command string to send

        Raises:
            Exception: If handle is not a valid MessageBasedResource
            Exception: If communication error occurs
        """
        # Debug output if enabled
        if Setting.VISA_Print_Enable:
            print(f"[{self.name}] Write: {command}")

        # Skip if VISA is disabled
        if not Setting.VISA_Send_Enable:
            return

        # Ensure we have a valid message-based resource
        if isinstance(self.handle, pyvisa.resources.MessageBasedResource):
            try:
                # Send command
                self.handle.write(command)

            except Exception:
                # Communication error occurred
                print(f"VISA Write Error: {self.name}")
                print(f"Address: {self.address}")
                print(f"Command: {command}")
                raise Exception("VISA Write Error")
        else:
            # Invalid handle state
            raise Exception("not MessageBasedResource")

    def read(self, count: Optional[int] = None) -> str:
        """
        Read data from the instrument.

        Args:
            count: Number of bytes to read (if specified, reads binary and decodes to UTF-8)

        Returns:
            Response string from the instrument

        Raises:
            Exception: If handle is not a valid MessageBasedResource
            Exception: If communication error occurs
        """
        # Debug output if enabled
        if Setting.VISA_Print_Enable:
            print(f"[{self.name}] Read")

        # Return dummy response if VISA is disabled
        if not Setting.VISA_Send_Enable:
            return "0"

        # Ensure we have a valid message-based resource
        if isinstance(self.handle, pyvisa.resources.MessageBasedResource):
            try:
                # Read data (binary or text mode)
                if isinstance(count, int):
                    response = self.handle.read_bytes(count).decode("utf-8")
                else:
                    response = self.handle.read()

                # Debug output if enabled
                if Setting.VISA_Print_Enable:
                    print(response)

                return response

            except Exception:
                # Communication error occurred
                print(f"VISA Read Error: {self.name}")
                raise Exception("VISA Read Error")
        else:
            # Invalid handle state
            raise Exception("not MessageBasedResource")

    def read_binary(self) -> bytes:
        """
        Read binary data from the instrument.

        Returns:
            Binary response data from the instrument

        Raises:
            Exception: If handle is not a valid MessageBasedResource
            Exception: If communication error occurs
        """
        # Debug output if enabled
        if Setting.VISA_Print_Enable:
            print(f"[{self.name}] Read Binary")

        # Return empty bytes if VISA is disabled
        if not Setting.VISA_Send_Enable:
            return b""

        # Ensure we have a valid message-based resource
        if isinstance(self.handle, pyvisa.resources.MessageBasedResource):
            try:
                # Read binary data
                return self.handle.read_raw()

            except Exception:
                # Communication error occurred
                print(f"VISA Read Binary Error: {self.name}")
                raise Exception("VISA Read Binary Error")
        else:
            # Invalid handle state
            raise Exception("not MessageBasedResource")

    def write_binary(self, command: bytes) -> None:
        """
        Send binary data to the instrument.

        Args:
            command: Binary command data to send

        Raises:
            Exception: If handle is not a valid MessageBasedResource
            Exception: If communication error occurs
        """
        # Debug output if enabled
        if Setting.VISA_Print_Enable:
            print(f"[{self.name}] Write Binary {command}")

        # Skip if VISA is disabled
        if not Setting.VISA_Send_Enable:
            return

        # Ensure we have a valid message-based resource
        if isinstance(self.handle, pyvisa.resources.MessageBasedResource):
            try:
                # Send binary command
                self.handle.write_raw(command)

            except Exception:
                # Communication error occurred
                print(f"VISA Write Binary Error: {self.name}")
                raise Exception("VISA Write Binary Error")
        else:
            # Invalid handle state
            raise Exception("not MessageBasedResource")

    def query_binary(self, command: str, delay_time: float = 0.1) -> bytes:
        """
        Send a text command and read binary response.

        Combines write (UTF-8 text) and read_binary operations with a delay.

        Args:
            command: Text command to send
            delay_time: Delay between write and read operations (seconds)

        Returns:
            Binary response data from the instrument

        Raises:
            Exception: If handle is not a valid MessageBasedResource
            Exception: If communication error occurs
        """
        # Debug output if enabled
        if Setting.VISA_Print_Enable:
            print(f"[{self.name}] Query Binary {command}")

        # Return dummy response if VISA is disabled
        if not Setting.VISA_Send_Enable:
            return b"0"

        # Ensure we have a valid message-based resource
        if isinstance(self.handle, pyvisa.resources.MessageBasedResource):
            try:
                # Send command and read binary response
                self.write(command)
                time.sleep(delay_time)
                response = self.read_binary()

                # Debug output if enabled
                if Setting.VISA_Print_Enable:
                    print(f"[{self.name}] Recv: {response}")

                return response

            except Exception:
                # Communication error occurred
                print(f"VISA Query Binary Error: {self.name}")
                raise Exception("VISA Query Binary Error")
        else:
            # Invalid handle state
            raise Exception("not MessageBasedResource")

    # Static utility methods for resource management
    @staticmethod
    def list_resources() -> List[str]:
        """
        List all available VISA resources.

        Returns:
            List of VISA resource addresses
        """
        try:
            resource_manager = pyvisa.ResourceManager()
            return list(resource_manager.list_resources())
        except Exception:
            return []

    @staticmethod
    def get_opened_connections() -> List[Tuple[str, pyvisa.resources.MessageBasedResource]]:
        """
        Get list of currently opened connections.

        Returns:
            List of (address, handle) tuples for opened connections
        """
        return opened_connections.copy()

    @staticmethod
    def close_all_connections() -> None:
        """
        Close all opened VISA connections.
        """
        global opened_connections

        for address, handle in opened_connections:
            try:
                if isinstance(handle, pyvisa.resources.MessageBasedResource):
                    handle.close()
            except Exception:
                pass  # Ignore errors during close

        opened_connections.clear()


class VISAManager:
    """
    Convenience class for managing multiple VISA instruments.

    Provides high-level interface for instrument discovery and management.
    """

    def __init__(self):
        """Initialize VISA manager."""
        self.instruments: dict[str, VISA] = {}

    def add_instrument(self, name: str, address: str) -> VISA:
        """
        Add and connect to an instrument.

        Args:
            name: Unique instrument identifier
            address: VISA resource address

        Returns:
            VISA instrument instance

        Raises:
            ValueError: If instrument name already exists
        """
        if name in self.instruments:
            raise ValueError(f"Instrument '{name}' already exists")

        instrument = VISA(name, address)
        self.instruments[name] = instrument
        return instrument

    def get_instrument(self, name: str) -> Optional[VISA]:
        """
        Get instrument by name.

        Args:
            name: Instrument identifier

        Returns:
            VISA instrument instance or None if not found
        """
        return self.instruments.get(name)

    def remove_instrument(self, name: str) -> bool:
        """
        Remove and close instrument connection.

        Args:
            name: Instrument identifier

        Returns:
            True if instrument was removed, False if not found
        """
        if name in self.instruments:
            self.instruments[name].close()
            del self.instruments[name]
            return True
        return False

    def close_all(self) -> None:
        """Close all instrument connections."""
        for instrument in self.instruments.values():
            instrument.close()
        self.instruments.clear()

    def list_instruments(self) -> List[str]:
        """
        List all managed instrument names.

        Returns:
            List of instrument names
        """
        return list(self.instruments.keys())

    @staticmethod
    def discover_instruments() -> List[str]:
        """
        Discover available VISA resources.

        Returns:
            List of available VISA resource addresses
        """
        return VISA.list_resources()
