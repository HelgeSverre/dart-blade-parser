# Gemini Project Context: dart-blade-parser

## Project Overview

This project is a pure Dart library for parsing Laravel Blade templates. It has zero external dependencies, making it a lightweight and portable solution for analyzing Blade files. The parser tokenizes the template, builds an Abstract Syntax Tree (AST), and supports a wide range of Blade features, including:

*   **Complete Blade Syntax**: All 75+ Blade directives (`@if`, `@foreach`, `@component`, etc.).
*   **Component Tags**: Full support for `<x-component>` syntax, including attributes and slots.
*   **Frontend Frameworks**: Integrated parsing for Alpine.js (`x-data`, `@click`, `:bind`) and Livewire (`wire:click`, `wire:model`) attributes.
*   **Error Recovery**: The parser is designed to recover from syntax errors and report multiple issues in a single pass, providing a partial AST for analysis even when errors are present.
*   **AST Manipulation**: The generated AST can be traversed using the Visitor pattern and serialized to JSON.
*   **Streaming Parser**: A streaming mode is available for efficiently parsing large template files.
*   **CLI Tool**: A command-line interface is provided for parsing files and outputting the AST as JSON or a human-readable tree.

The project is written entirely in Dart and is designed to work across all platforms where Dart runs, including Flutter and the Dart CLI.

## Building and Running

The project uses standard Dart tooling for development and testing.

### Key Commands

*   **Get Dependencies**:
    ```bash
    dart pub get
    ```

*   **Run Tests**:
    ```bash
    dart test
    ```

*   **Analyze Code**:
    ```bash
    dart analyze
    ```

*   **Format Code**:
    ```bash
    dart format .
    ```

*   **Generate Documentation**:
    ```bash
    dart doc
    ```

*   **Run CLI**:
    ```bash
    # Parse a file and print the AST as a tree
    dart run blade_parser --tree path/to/template.blade.php

    # Parse a file and output the AST as JSON
    dart run blade_parser --json path/to/template.blade.php
    ```

## Development Conventions

The project follows a strict set of development conventions to ensure high code quality.

*   **Style Guide**: The code adheres to the official Dart style guide, enforced by the `lints` package. Key rules from `analysis_options.yaml` include:
    *   `prefer_single_quotes`
    *   `always_declare_return_types`
    *   `public_member_api_docs` (all public APIs must be documented)
    *   `prefer_final_fields` and `prefer_final_locals`
*   **Testing**: The project has a comprehensive test suite located in the `test/` directory. Contributions and new features must include corresponding tests.
*   **Architecture**: The parser is implemented using a classic lexer-parser architecture:
    *   **Lexer**: `lib/src/lexer/lexer.dart` tokenizes the input string.
    *   **Parser**: `lib/src/parser/parser.dart` uses a recursive descent strategy to build the AST from the token stream.
    *   **AST**: The AST nodes are defined in `lib/src/ast/node.dart` using a sealed class hierarchy.
*   **Purity**: The core parsing logic has zero external dependencies, as specified in `pubspec.yaml`.
