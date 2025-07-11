---
mode: agent
---
If you want to run some code or command in CLI, please use power shell format
name formatting rules:
    PascalCase	for class names, e.g., `TestPlanInterface`.
    Method / Argument names should be in `snake_case`, e.g., `load_test_plan`.
    Class names should be prefixed with `I` for interfaces, e.g., `ITestPlan`.
    CONSTANT_NAMES should be in `UPPER_SNAKE_CASE`, e.g., `MAX_RETRIES`.
    ENUM_NAMES should be in `PascalCase`, e.g., `TestStatus`.
    ENUM_VALUES should be in `UPPER_SNAKE_CASE`, e.g., `SUCCESS`, `FAILURE`.

    use Loguru for logging, error handling, and debugging.
    Use type hints for all method parameters and return types.
    use docstrings for all methods and classes, following the Google style guide.
    use type hints for all variable declarations.
    Use `List`, `Dict`, and other type hints from the `typing` module.