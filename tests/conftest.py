import os

# Default to localhost in test environment so module import succeeds on machines outside Thailand plant
os.environ.setdefault("ACBEL_MES_IP", "127.0.0.1")

