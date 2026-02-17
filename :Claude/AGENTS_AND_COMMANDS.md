# Claude Code: Agents and Commands Reference

## Available Agents

Agents are specialized assistants that can be launched using the Task tool to handle complex, multi-step tasks autonomously.

### 1. Bash Agent
- **Purpose**: Command execution specialist for running bash commands
- **Best for**:
  - Git operations
  - Command execution
  - Terminal tasks
- **Tools available**: Bash

### 2. General-purpose Agent
- **Purpose**: General-purpose agent for researching complex questions, searching for code, and executing multi-step tasks
- **Best for**:
  - When searching for keywords or files with multiple attempts
  - Complex research tasks
  - Multi-step operations
- **Tools available**: All tools (*)

### 3. Statusline-setup Agent
- **Purpose**: Configure the user's Claude Code status line setting
- **Best for**: Status line configuration
- **Tools available**: Read, Edit

### 4. Explore Agent
- **Purpose**: Fast agent specialized for exploring codebases
- **Best for**:
  - Finding files by patterns (e.g., `src/components/**/*.tsx`)
  - Searching code for keywords (e.g., "API endpoints")
  - Answering questions about the codebase (e.g., "how do API endpoints work?")
- **Thoroughness levels**:
  - `quick` - Basic searches
  - `medium` - Moderate exploration
  - `very thorough` - Comprehensive analysis across multiple locations
- **Tools available**: All tools except Task, ExitPlanMode, Edit, Write, NotebookEdit

### 5. Plan Agent
- **Purpose**: Software architect agent for designing implementation plans
- **Best for**:
  - Planning implementation strategy for a task
  - Step-by-step planning
  - Identifying critical files
  - Considering architectural trade-offs
- **Tools available**: All tools except Task, ExitPlanMode, Edit, Write, NotebookEdit

## Available Commands

Commands are invoked using the Skill tool with a slash prefix (e.g., `/commit`, `/review-pr`).

### Built-in Commands

- **/help** - Get help with using Claude Code
- **/clear** - Clear the conversation
- **/tasks** - List running background tasks

### Command Usage

To use a command, simply type it with a slash prefix:
```
/commit
/commit -m "Fix bug"
/review-pr 123
```

Commands can accept arguments that modify their behavior.

## Tool Categories

### File Operations
- **Read** - Read file contents
- **Write** - Create or overwrite files
- **Edit** - Perform exact string replacements
- **Glob** - Find files by pattern matching
- **Grep** - Search file contents with regex

### Xcode Operations
- **XcodeRead** - Read files in Xcode project structure
- **XcodeWrite** - Create/overwrite files in Xcode project
- **XcodeUpdate** - Edit files in Xcode project
- **XcodeLS** - List files in Xcode project structure
- **XcodeGlob** - Find files in Xcode project by pattern
- **XcodeGrep** - Search files in Xcode project
- **XcodeMV** - Move/rename files in Xcode project
- **XcodeRM** - Remove files from Xcode project
- **XcodeMakeDir** - Create directories in Xcode project

### Xcode Build & Test
- **BuildProject** - Build the Xcode project
- **RunAllTests** - Run all tests from active scheme
- **RunSomeTests** - Run specific tests
- **GetTestList** - Get available tests
- **GetBuildLog** - Get build log
- **XcodeListNavigatorIssues** - List issues in Xcode
- **XcodeRefreshCodeIssuesInFile** - Get compiler diagnostics for a file

### Xcode Development
- **ExecuteSnippet** - Run code snippet in file context
- **RenderPreview** - Build and render SwiftUI preview

### Documentation
- **DocumentationSearch** - Search Apple Developer Documentation

### Version Control
- **Bash** - Execute git commands via bash

### Web & Search
- **WebFetch** - Fetch and analyze web content
- **WebSearch** - Search the web for information

### Task Management
- **TodoWrite** - Create and manage task lists
- **Task** - Launch specialized agents
- **TaskOutput** - Retrieve output from running tasks

### Planning & Questions
- **EnterPlanMode** - Enter planning mode for complex tasks
- **ExitPlanMode** - Exit planning mode and request approval
- **AskUserQuestion** - Ask user questions during execution

## Best Practices

1. **Use specialized agents** for complex, multi-step tasks
2. **Launch agents in parallel** when tasks are independent
3. **Use Explore agent** when researching codebases rather than running searches directly
4. **Use Plan agent** for implementation planning before writing code
5. **Prefer Xcode tools** when working in Xcode projects
6. **Use DocumentationSearch** for the latest Apple framework information

## Getting Help

- Report issues at: https://github.com/anthropics/claude-code/issues
- Use `/help` command for interactive help
