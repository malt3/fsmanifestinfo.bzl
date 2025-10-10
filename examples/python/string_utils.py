"""String utility functions demonstrating library code."""

from typing import List
import re


class StringUtils:
    """Utility class for string operations."""

    @staticmethod
    def split_words(text: str) -> List[str]:
        """Split text into words."""
        # Use regex to split on whitespace and punctuation
        words = re.findall(r'\b\w+\b', text)
        return words

    @staticmethod
    def reverse_words(text: str) -> str:
        """Reverse the order of words in text."""
        words = text.split()
        return ' '.join(reversed(words))

    @staticmethod
    def join_with_commas(words: List[str]) -> str:
        """Join words with commas."""
        return ', '.join(words)

    @staticmethod
    def capitalize_words(text: str) -> str:
        """Capitalize the first letter of each word."""
        return ' '.join(word.capitalize() for word in text.split())

    @staticmethod
    def count_vowels(text: str) -> int:
        """Count the number of vowels in text."""
        vowels = 'aeiouAEIOU'
        return sum(1 for char in text if char in vowels)

    @staticmethod
    def is_palindrome(text: str) -> bool:
        """Check if text is a palindrome (ignoring case and spaces)."""
        cleaned = ''.join(text.lower().split())
        return cleaned == cleaned[::-1]