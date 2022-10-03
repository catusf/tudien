# Use git log to get commit IDs
git diff ab872f5..ea05b27 > mypatch.patch

# Rename patch file accordingly
git apply mypatch.patch