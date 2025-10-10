"""JSON processing utility using PyYAML and built-in json."""

import json
from typing import Any
import yaml


class JsonProcessor:
    """Utility class for JSON processing with YAML support."""

    def __init__(self):
        """Initialize the JSON processor."""
        self.indent = 2

    def to_json(self, data: Any) -> str:
        """Convert data to JSON string."""
        return json.dumps(data, indent=self.indent, sort_keys=True)

    def from_json(self, json_str: str) -> Any:
        """Parse JSON string to Python object."""
        return json.loads(json_str)

    def to_yaml(self, data: Any) -> str:
        """Convert data to YAML string."""
        return yaml.dump(data, default_flow_style=False, sort_keys=True)

    def from_yaml(self, yaml_str: str) -> Any:
        """Parse YAML string to Python object."""
        return yaml.safe_load(yaml_str)

    def pretty_print(self, data: Any):
        """Pretty print data as JSON."""
        print(self.to_json(data))