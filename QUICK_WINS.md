# Quick Wins & Chores List

**Generated:** 2025-10-10  
**Total Items:** 28 tasks organized by effort level

---

## 🟢 EASY WINS (5-30 min each) - 15 tasks

### Code Cleanup - Core Library (4 tasks)

1. **Remove unused variable `tagStartPos`** (~2 min)
   - File: `lib/src/lexer/lexer.dart:861`
   - Simply delete the unused variable declaration
   ```dart
   // Line 861: final tagStartPos = _position; // DELETE THIS
   ```

2. **Remove unused variable `attrStart`** (~2 min)
   - File: `lib/src/lexer/lexer.dart:949`
   - Delete the unused variable

3. **Remove unused method `_peekWord`** (~2 min)
   - File: `lib/src/lexer/lexer.dart:1093`
   - Delete the entire unused method (appears to be dead code)

4. **Remove unused variable `startToken`** (~2 min)
   - File: `lib/src/parser/parser.dart:1072`
   - Delete the unused variable

**Impact:** Cleaner code, fewer linter warnings (4 warnings eliminated)

---

### Code Cleanup - Tests (6 tasks)

5. **Remove unnecessary null assertions in tests** (~5 min)
   - Files:
     - `test/contract/parser_html_contract_test.dart:254-255` (2 places)
     - `test/integration/html_error_test.dart:130-132` (3 places)
     - `test/unit/parser/html_element_parser_test.dart:257-258` (2 places)
   - Replace `.where(...).first!` with `.firstWhere(...)`

6. **Remove unused variable `directives`** (~1 min)
   - File: `test/performance/throughput_benchmark_test.dart:224`

7. **Remove unused variables `node` (2 instances)** (~2 min)
   - Files:
     - `test/unit/streaming/streaming_incremental_test.dart:158`
     - `test/unit/streaming/streaming_incremental_test.dart:214`

8. **Remove unused field `_blue`** (~1 min)
   - File: `tools/acid/reporters/console_reporter.dart:12`

9. **Add explicit type arguments to `List<dynamic>`** (~10 min)
   - Files:
     - `test/contract/ast_contract_test.dart:91`
     - `test/contract/html_attribute_contract_test.dart:191`
     - `test/contract/html_element_contract_test.dart:192`
     - `test/integration/basic_parsing_test.dart:77`
   - Change `List` to `List<String>` or appropriate type

10. **Add explicit type arguments to `Map<dynamic, dynamic>`** (~10 min)
    - File: `test/contract/html_element_contract_test.dart:187-191` (6 places)
    - File: `test/unit/parser/component_attributes_test.dart:190`
    - Change to `Map<String, dynamic>` or appropriate types

**Impact:** Cleaner tests, 18+ warnings eliminated

---

### Documentation Cleanup (5 tasks)

11. **Delete old HTML report files** (~1 min)
    ```bash
    rm my_report.html test_report.html
    ```
    - These are generated files that shouldn't be in git

12. **Add HTML reports to .gitignore** (~1 min)
    ```bash
    echo "*.html" >> .gitignore
    echo "!docs/**/*.html" >> .gitignore
    ```

13. **Consolidate duplicate documentation files** (~10 min)
    - We have multiple status files that overlap:
      - `STATUS.md` (outdated - Oct 8)
      - `IMPLEMENTATION_STATUS.md` (current - Oct 10)
      - `COMPLETION_REPORT.md` (today's work)
    - **Action:** Archive `STATUS.md`, keep the other two

14. **Update CHANGELOG.md with today's fixes** (~15 min)
    - Add entry for v1.0.1 with:
      - Empty tag validation fix
      - StringBuffer refactor
      - URL parsing fix

15. **Clean up root directory organization** (~10 min)
    - Move old status reports to `archive/`
    - Keep only: README, CHANGELOG, TODO, IMPROVEMENT_PLAN, IMPLEMENTATION_STATUS

**Impact:** Cleaner repo, easier navigation

---

## 🟡 MEDIUM EFFORT (30-60 min each) - 8 tasks

### Type Inference Fixes (5 tasks)

16. **Fix Future.delayed type inference** (~30 min)
    - Files (6 instances):
      - `examples/memory_visualization.dart:71`
      - `examples/streaming_comparison.dart:58`
      - `examples/streaming_demo.dart:91`
      - `test/unit/streaming/streaming_html_test.dart:233`
      - `test/unit/streaming/streaming_incremental_test.dart:219`
    - Change: `Future.delayed(...)` to `Future<void>.delayed(...)`

17. **Fix asFuture type inference** (~15 min)
    - Files (2 instances):
      - `examples/memory_visualization.dart:90`
      - `examples/streaming_demo.dart:96`
    - Add explicit type: `.asFuture<void>()`

18. **Fix print statements in bin/blade_parser.dart** (~20 min)
    - File: `bin/blade_parser.dart` (6 instances)
    - Options:
      - Keep them (it's a CLI tool, print is acceptable)
      - Add `// ignore: avoid_print` comments
      - Use `stderr.writeln()` for errors

19. **Remove unnecessary string interpolation braces** (~5 min)
    - File: `bin/blade_parser.dart:105, 111`
    - Change: `${variable}` to `$variable` when no computation needed

20. **Fix print statements in examples** (~20 min)
    - Files: `examples/memory_visualization.dart` (many prints)
    - Add `// ignore: avoid_print` to examples (they're demos)

**Impact:** ~30 warnings eliminated

---

### Git & Version Control (3 tasks)

21. **Stage and commit recent changes** (~30 min)
    - Modified files need committing:
      - `lib/src/lexer/lexer.dart` (empty tag fix)
      - `TODO.md` (updated status)
      - Performance test improvements
    - Commit message: "fix: add empty tag name validation"

22. **Add new files to git or .gitignore** (~15 min)
    - New documentation files to commit:
      - `COMPLETION_REPORT.md`
      - `IMPLEMENTATION_STATUS.md`
      - `IMPROVEMENT_PLAN.md`
    - New test files (decide: commit or ignore as WIP)

23. **Update version in pubspec.yaml** (~5 min)
    - Current: `1.0.0`
    - Change to: `1.0.1` (bug fix release)
    - Or: `1.1.0-dev` (pre-release)

**Impact:** Clean git history, proper versioning

---

## 🔴 LARGER TASKS (1-2 hours) - 5 tasks

### Code Quality Improvements

24. **Add missing dartdoc comments** (~2 hours)
    - Public API methods without documentation
    - Focus on: `lib/blade_parser.dart`, `lib/src/parser/parser.dart`

25. **Create AGENTS.md file** (~1 hour)
    - Document common commands for AI agents
    - Include: test commands, build commands, lint commands
    - Helps future AI interactions

26. **Optimize linter rules** (~1 hour)
    - Review `analysis_options.yaml`
    - Disable overly strict rules for examples/tools
    - Enable stricter rules for core lib

27. **Archive old documentation** (~30 min)
    - Move files from `archive/` that are truly obsolete
    - Delete or consolidate duplicate status reports
    - Clean up `specs/` directory

28. **Run `dart fix --apply`** (~30 min)
    - Automatically fix many linter issues
    - Review changes before committing
    - May fix 100+ issues automatically

**Impact:** Professional codebase, better maintainability

---

## 📊 Summary by Category

| Category | Tasks | Est. Time | Warnings Fixed |
|----------|-------|-----------|----------------|
| **Code Cleanup - Core** | 4 | 10 min | 4 |
| **Code Cleanup - Tests** | 6 | 30 min | 18+ |
| **Documentation** | 5 | 40 min | 0 |
| **Type Inference** | 5 | 90 min | 30+ |
| **Git & Versioning** | 3 | 50 min | 0 |
| **Larger Tasks** | 5 | 5 hours | 100+ |
| **TOTAL** | **28** | **~7.5 hours** | **~150+** |

---

## 🎯 Recommended Priority Order

### Phase 1: Super Quick (15 min total)
1. Remove 4 unused variables from core lib
2. Delete HTML report files
3. Add HTML to .gitignore

**Result:** 4 warnings gone, cleaner repo

### Phase 2: Test Cleanup (45 min total)
4. Remove unnecessary null assertions
5. Remove unused test variables
6. Fix strict_raw_type warnings

**Result:** 24+ warnings gone

### Phase 3: Documentation (40 min total)
7. Consolidate status files
8. Update CHANGELOG
9. Organize root directory

**Result:** Professional documentation

### Phase 4: Type Fixes (90 min total)
10. Fix Future.delayed inference
11. Fix asFuture inference
12. Handle print statements

**Result:** 30+ warnings gone

### Phase 5: Git Hygiene (50 min total)
13. Commit empty tag fix
14. Update version number
15. Add/ignore new files

**Result:** Clean git state, ready for release

### Phase 6: Optional Polish (5 hours)
16. Run dart fix --apply
17. Add dartdoc comments
18. Create AGENTS.md
19. Optimize linter rules

**Result:** Production-quality codebase

---

## 🚀 Quick Start Commands

```bash
# Remove unused variables (Phase 1)
# Edit files manually or use sed

# Delete HTML reports
rm my_report.html test_report.html
echo "*.html" >> .gitignore

# Auto-fix many issues
dart fix --apply

# Check progress
dart analyze | grep "warning" | wc -l

# Run tests
dart test

# Commit changes
git add -A
git commit -m "chore: cleanup unused variables and linter warnings"
```

---

## 💡 Expected Outcome

**Current state:**
- 577 info/warnings
- Cluttered root directory
- Uncommitted changes

**After all quick wins:**
- <50 warnings (90% reduction)
- Clean, organized structure
- Ready for v1.0.1 release
- Professional appearance

**Time investment:** ~3 hours for phases 1-5 (eliminates 150+ warnings)
