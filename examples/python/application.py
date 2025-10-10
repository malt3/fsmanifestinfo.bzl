"""Main application demonstrating FSManifestInfo with Python dependencies."""

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Dict, Any, List

# Third-party imports demonstrating external dependencies
import click
import requests
import yaml
# import numpy as np  # Commented out due to GLIBC compatibility
from runfiles import Runfiles

# Local imports
from json_processor import JsonProcessor
from string_utils import StringUtils


class Application:
    """Python application demonstrating FSManifestInfo with various dependencies."""

    def __init__(self):
        """Initialize application and load configuration."""
        self.json_processor = JsonProcessor()
        self.string_utils = StringUtils()
        self.runfiles = Runfiles.Create()
        self.config = self._load_config()
        self.readme = self._load_readme()

    def _load_config(self) -> str:
        """Load configuration from data file using bazel-runfiles."""
        # Resolve the config file through runfiles
        config_path = self.runfiles.Rlocation("_main/config/app.config")
        with open(config_path, 'r') as f:
            content = f.read().strip()
            print(f"Loaded config via bazel-runfiles from {config_path}")
            return content

    def _load_readme(self) -> str:
        """Load README from resources using bazel-runfiles."""
        readme_path = self.runfiles.Rlocation("_main/resources/README.txt")
        with open(readme_path, 'r') as f:
            content = f.read().strip()
            print(f"Loaded README via bazel-runfiles from {readme_path}")
            return content

    def process_message(self, message: str, reverse: bool = False) -> Dict[str, Any]:
        """Process a message with various transformations."""
        if reverse:
            message = self.string_utils.reverse_words(message)

        words = self.string_utils.split_words(message)

        # Calculate word statistics without numpy
        word_lengths = [len(w) for w in words]
        stats = {
            'mean_length': sum(word_lengths) / len(word_lengths) if word_lengths else 0,
            'max_length': max(word_lengths) if word_lengths else 0,
            'min_length': min(word_lengths) if word_lengths else 0,
        }

        return {
            'message': message,
            'words': words,
            'word_count': len(words),
            'word_stats': stats,
            'config': self.config.split('\n')[0] if self.config else '',
        }

    def run(self, args: argparse.Namespace):
        """Run the application with given arguments."""
        click.echo(click.style("Starting FSManifestInfo Python Application", fg='green', bold=True))

        message = args.message or "Hello from FSManifestInfo Python Application with Third-Party Dependencies"

        result = self.process_message(message, args.reverse)

        if args.json:
            # Output as JSON
            print(self.json_processor.to_json(result))
        else:
            # Pretty print output
            print("\n" + "=" * 50)
            print("FSManifestInfo Python Application")
            print("=" * 50)
            print(f"Message: {result['message']}")
            print(f"Words: {self.string_utils.join_with_commas(result['words'])}")
            print(f"Word count: {result['word_count']}")
            print(f"Word stats: mean={result['word_stats']['mean_length']:.2f}, "
                  f"max={result['word_stats']['max_length']}, "
                  f"min={result['word_stats']['min_length']}")
            print(f"Config: {result['config']}")
            print()
            print("This demonstrates:")
            print("- Python libraries (json_processor, string_utils)")
            print("- External deps (Click, Requests, PyYAML, bazel-runfiles)")
            print("- Data dependencies loaded via bazel-runfiles")
            print("- Layer separation (platform/external/application)")
            print(f"- README content: {self.readme[:50]}..." if len(self.readme) > 50 else f"- README: {self.readme}")

        if args.test_request:
            print("\n" + "-" * 50)
            print("Testing requests library:")
            try:
                response = requests.get('https://api.github.com', timeout=5)
                print(f"GitHub API Status: {response.status_code}")
                data = response.json()
                print(f"Current rate limit: {data.get('rate_limit_url', 'N/A')}")
            except Exception as e:
                print(f"Request failed: {e}")


def main():
    """Main entry point for the application."""
    parser = argparse.ArgumentParser(
        description='FSManifestInfo Python Application Example',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s --message "Hello World"
  %(prog)s --json
  %(prog)s --reverse --message "One Two Three"
  %(prog)s --test-request
        """
    )

    parser.add_argument('-m', '--message', type=str,
                        help='Message to process')
    parser.add_argument('-j', '--json', action='store_true',
                        help='Output as JSON')
    parser.add_argument('-r', '--reverse', action='store_true',
                        help='Reverse word order')
    parser.add_argument('-t', '--test-request', action='store_true',
                        help='Test HTTP request capability')

    args = parser.parse_args()

    try:
        app = Application()
        app.run(args)
    except Exception as e:
        print(f"Application failed: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()