"""
Additional test module for VISA Bundle edge cases and error scenarios
"""

import pytest
import sys
import os
from unittest.mock import Mock, patch, MagicMock
import pyvisa

# Add the src directory to the path to import the package
src_path = os.path.join(os.path.dirname(
    os.path.dirname(os.path.abspath(__file__))), 'src')
sys.path.insert(0, src_path)

try:
    from visa_bundle import VISA, VISAManager, opened_connections, Opened_List, Setting
    IMPORT_SUCCESS = True
except ImportError:
    IMPORT_SUCCESS = False


class TestVISAAdvancedScenarios:
    """Advanced test scenarios for VISA functionality"""

    @patch('pyvisa.ResourceManager')
    def test_visa_query_with_mock_communication(self, mock_rm):
        """Test VISA query with mocked successful communication"""
        if not IMPORT_SUCCESS:
            pytest.skip("Failed to import required modules")

        # Set up mock for successful communication
        mock_resource = Mock(spec=pyvisa.resources.MessageBasedResource)
        mock_resource.query.return_value = "Test Device v1.0"
        mock_rm.return_value.open_resource.return_value = mock_resource

        original_send = Setting.VISA_Send_Enable
        original_print = Setting.VISA_Print_Enable

        try:
            Setting.VISA_Send_Enable = True
            Setting.VISA_Print_Enable = True
            VISA.close_all_connections()

            visa = VISA("test_device", "MOCK::INSTR")
            result = visa.query("*IDN?")

            assert result == "Test Device v1.0"
            mock_resource.query.assert_called_with("*IDN?", None)

        finally:
            Setting.VISA_Send_Enable = original_send
            Setting.VISA_Print_Enable = original_print
            VISA.close_all_connections()

    @patch('pyvisa.ResourceManager')
    def test_visa_write_with_mock_communication(self, mock_rm):
        """Test VISA write with mocked communication"""
        if not IMPORT_SUCCESS:
            pytest.skip("Failed to import required modules")

        mock_resource = Mock(spec=pyvisa.resources.MessageBasedResource)
        mock_rm.return_value.open_resource.return_value = mock_resource

        original_send = Setting.VISA_Send_Enable

        try:
            Setting.VISA_Send_Enable = True
            VISA.close_all_connections()

            visa = VISA("test_device", "MOCK::INSTR")
            visa.write("*RST")

            mock_resource.write.assert_called_with("*RST")

        finally:
            Setting.VISA_Send_Enable = original_send
            VISA.close_all_connections()

    @patch('pyvisa.ResourceManager')
    def test_visa_read_with_mock_communication(self, mock_rm):
        """Test VISA read with mocked communication"""
        if not IMPORT_SUCCESS:
            pytest.skip("Failed to import required modules")

        mock_resource = Mock(spec=pyvisa.resources.MessageBasedResource)
        mock_resource.read.return_value = "Test Response"
        mock_rm.return_value.open_resource.return_value = mock_resource

        original_send = Setting.VISA_Send_Enable

        try:
            Setting.VISA_Send_Enable = True
            VISA.close_all_connections()

            visa = VISA("test_device", "MOCK::INSTR")
            result = visa.read()

            assert result == "Test Response"
            mock_resource.read.assert_called_once()

        finally:
            Setting.VISA_Send_Enable = original_send
            VISA.close_all_connections()

    @patch('pyvisa.ResourceManager')
    def test_visa_read_binary_with_mock_communication(self, mock_rm):
        """Test VISA read_binary with mocked communication"""
        if not IMPORT_SUCCESS:
            pytest.skip("Failed to import required modules")

        mock_resource = Mock(spec=pyvisa.resources.MessageBasedResource)
        mock_resource.read_raw.return_value = b"binary_data"
        mock_rm.return_value.open_resource.return_value = mock_resource

        original_send = Setting.VISA_Send_Enable

        try:
            Setting.VISA_Send_Enable = True
            VISA.close_all_connections()

            visa = VISA("test_device", "MOCK::INSTR")
            result = visa.read_binary()

            assert result == b"binary_data"
            mock_resource.read_raw.assert_called_once()

        finally:
            Setting.VISA_Send_Enable = original_send
            VISA.close_all_connections()

    @patch('pyvisa.ResourceManager')
    def test_visa_read_with_count_parameter(self, mock_rm):
        """Test VISA read with count parameter (binary mode)"""
        if not IMPORT_SUCCESS:
            pytest.skip("Failed to import required modules")

        mock_resource = Mock(spec=pyvisa.resources.MessageBasedResource)
        mock_resource.read_bytes.return_value = b"binary_response"
        mock_rm.return_value.open_resource.return_value = mock_resource

        original_send = Setting.VISA_Send_Enable

        try:
            Setting.VISA_Send_Enable = True
            VISA.close_all_connections()

            visa = VISA("test_device", "MOCK::INSTR")
            result = visa.read(count=10)

            assert result == "binary_response"
            mock_resource.read_bytes.assert_called_with(10)

        finally:
            Setting.VISA_Send_Enable = original_send
            VISA.close_all_connections()

    @patch('pyvisa.ResourceManager')
    def test_visa_manager_add_duplicate_instrument(self, mock_rm):
        """Test VISAManager handling of duplicate instrument names"""
        if not IMPORT_SUCCESS or VISAManager is None:
            pytest.skip("VISAManager not available")

        mock_resource = Mock(spec=pyvisa.resources.MessageBasedResource)
        mock_rm.return_value.open_resource.return_value = mock_resource

        original_send = Setting.VISA_Send_Enable

        try:
            Setting.VISA_Send_Enable = True
            manager = VISAManager()

            # Add first instrument
            manager.add_instrument("test_device", "MOCK1::INSTR")

            # Try to add instrument with same name - should raise ValueError
            with pytest.raises(ValueError, match="already exists"):
                manager.add_instrument("test_device", "MOCK2::INSTR")

        finally:
            Setting.VISA_Send_Enable = original_send

    @patch('pyvisa.ResourceManager')
    def test_visa_manager_get_and_remove_instrument(self, mock_rm):
        """Test VISAManager get and remove instrument operations"""
        if not IMPORT_SUCCESS or VISAManager is None:
            pytest.skip("VISAManager not available")

        mock_resource = Mock(spec=pyvisa.resources.MessageBasedResource)
        mock_rm.return_value.open_resource.return_value = mock_resource

        original_send = Setting.VISA_Send_Enable

        try:
            Setting.VISA_Send_Enable = True
            manager = VISAManager()

            # Add instrument
            added_instrument = manager.add_instrument(
                "test_device", "MOCK::INSTR")

            # Get instrument
            retrieved_instrument = manager.get_instrument("test_device")
            assert retrieved_instrument is added_instrument

            # Remove instrument
            result = manager.remove_instrument("test_device")
            assert result is True

            # Verify it's gone
            assert manager.get_instrument("test_device") is None
            assert "test_device" not in manager.list_instruments()

        finally:
            Setting.VISA_Send_Enable = original_send

    @patch('pyvisa.ResourceManager')
    def test_visa_close_connection(self, mock_rm):
        """Test VISA close connection functionality"""
        if not IMPORT_SUCCESS:
            pytest.skip("Failed to import required modules")

        mock_resource = Mock(spec=pyvisa.resources.MessageBasedResource)
        mock_rm.return_value.open_resource.return_value = mock_resource

        original_send = Setting.VISA_Send_Enable

        try:
            Setting.VISA_Send_Enable = True
            VISA.close_all_connections()

            visa = VISA("test_device", "MOCK::INSTR")

            # Verify connection was added
            connections = VISA.get_opened_connections()
            assert len(connections) >= 1

            # Close the connection
            visa.close()

            # Verify handle is cleared
            assert visa.handle is None

            # Verify close was called on mock
            mock_resource.close.assert_called_once()

        finally:
            Setting.VISA_Send_Enable = original_send
            VISA.close_all_connections()

    @patch('pyvisa.ResourceManager')
    def test_visa_query_with_delay(self, mock_rm):
        """Test VISA query with delay parameter"""
        if not IMPORT_SUCCESS:
            pytest.skip("Failed to import required modules")

        mock_resource = Mock(spec=pyvisa.resources.MessageBasedResource)
        mock_resource.query.return_value = "Delayed Response"
        mock_rm.return_value.open_resource.return_value = mock_resource

        original_send = Setting.VISA_Send_Enable

        try:
            Setting.VISA_Send_Enable = True
            VISA.close_all_connections()

            visa = VISA("test_device", "MOCK::INSTR")
            result = visa.query("*IDN?", delay_time=0.1)

            assert result == "Delayed Response"
            mock_resource.query.assert_called_with("*IDN?", 0.1)

        finally:
            Setting.VISA_Send_Enable = original_send
            VISA.close_all_connections()


class TestVISAErrorScenarios:
    """Test error handling scenarios"""

    @patch('pyvisa.ResourceManager')
    def test_visa_open_connection_retry_failure(self, mock_rm):
        """Test VISA open connection failure after retries"""
        if not IMPORT_SUCCESS:
            pytest.skip("Failed to import required modules")

        # Mock that always raises exception
        mock_rm.return_value.open_resource.side_effect = Exception(
            "Connection failed")

        original_send = Setting.VISA_Send_Enable

        try:
            Setting.VISA_Send_Enable = True
            VISA.close_all_connections()

            # Should raise exception after retries
            with pytest.raises(Exception, match="VISA Open Error"):
                VISA("test_device", "MOCK::INSTR")

        finally:
            Setting.VISA_Send_Enable = original_send

    @patch('pyvisa.ResourceManager')
    def test_visa_query_error_handling(self, mock_rm):
        """Test VISA query error handling"""
        if not IMPORT_SUCCESS:
            pytest.skip("Failed to import required modules")

        mock_resource = Mock(spec=pyvisa.resources.MessageBasedResource)
        mock_resource.query.side_effect = Exception("Query failed")
        mock_rm.return_value.open_resource.return_value = mock_resource

        original_send = Setting.VISA_Send_Enable

        try:
            Setting.VISA_Send_Enable = True
            VISA.close_all_connections()

            visa = VISA("test_device", "MOCK::INSTR")

            with pytest.raises(Exception, match="VISA Query Error"):
                visa.query("*IDN?")

        finally:
            Setting.VISA_Send_Enable = original_send
            VISA.close_all_connections()

    @patch('pyvisa.ResourceManager')
    def test_visa_write_error_handling(self, mock_rm):
        """Test VISA write error handling"""
        if not IMPORT_SUCCESS:
            pytest.skip("Failed to import required modules")

        mock_resource = Mock(spec=pyvisa.resources.MessageBasedResource)
        mock_resource.write.side_effect = Exception("Write failed")
        mock_rm.return_value.open_resource.return_value = mock_resource

        original_send = Setting.VISA_Send_Enable

        try:
            Setting.VISA_Send_Enable = True
            VISA.close_all_connections()

            visa = VISA("test_device", "MOCK::INSTR")

            with pytest.raises(Exception, match="VISA Write Error"):
                visa.write("*RST")

        finally:
            Setting.VISA_Send_Enable = original_send
            VISA.close_all_connections()

    @patch('pyvisa.ResourceManager')
    def test_visa_read_error_handling(self, mock_rm):
        """Test VISA read error handling"""
        if not IMPORT_SUCCESS:
            pytest.skip("Failed to import required modules")

        mock_resource = Mock(spec=pyvisa.resources.MessageBasedResource)
        mock_resource.read.side_effect = Exception("Read failed")
        mock_rm.return_value.open_resource.return_value = mock_resource

        original_send = Setting.VISA_Send_Enable

        try:
            Setting.VISA_Send_Enable = True
            VISA.close_all_connections()

            visa = VISA("test_device", "MOCK::INSTR")

            with pytest.raises(Exception, match="VISA Read Error"):
                visa.read()

        finally:
            Setting.VISA_Send_Enable = original_send
            VISA.close_all_connections()

    @patch('pyvisa.ResourceManager')
    def test_visa_invalid_handle_operations(self, mock_rm):
        """Test operations with invalid handle type"""
        if not IMPORT_SUCCESS:
            pytest.skip("Failed to import required modules")

        # Mock a non-MessageBasedResource
        mock_resource = Mock()  # Not spec'd as MessageBasedResource
        mock_rm.return_value.open_resource.return_value = mock_resource

        original_send = Setting.VISA_Send_Enable

        try:
            Setting.VISA_Send_Enable = True
            VISA.close_all_connections()

            visa = VISA("test_device", "MOCK::INSTR")

            # Should raise "not MessageBasedResource" error
            with pytest.raises(Exception, match="not MessageBasedResource"):
                visa.query("*IDN?")

            with pytest.raises(Exception, match="not MessageBasedResource"):
                visa.write("*RST")

            with pytest.raises(Exception, match="not MessageBasedResource"):
                visa.read()

        finally:
            Setting.VISA_Send_Enable = original_send
            VISA.close_all_connections()


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
