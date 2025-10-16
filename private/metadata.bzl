"""Defines well-known fields for the "metadata" and "defaults" fields of FSManifestInfo.

These are merely suggestions. If well known fields are used, the meaning of each field is known.
Any field is optional, and additional, custom fields may be present as well.
"""

well_known_fields = {
    "mode": "File mode (int, e.g. 0o755).",
    "uid": "User ID (int).",
    "gid": "Group ID (int).",
    "owner": "User name (string).",
    "group": "Group name (string).",
    "mtime": "Modification time (int, epoch seconds).",
    "xattrs": "Dictionary of extended attributes (string to string).",
}
