# Security and privacy

LocalSwitcher requires macOS Input Monitoring and Accessibility because it
observes keyboard events and replaces text in the focused application.

The application:

- processes input locally;
- does not send typed text to a server;
- does not include telemetry;
- pauses while macOS Secure Input is active;
- permanently excludes supported password managers;
- does not write typed words to its debug log;
- ignores its own synthesized keyboard events;
- keeps automatic updates disabled until a project-owned signed feed exists.

Do not include passwords, tokens, personal text, or raw keystroke logs in bug
reports. Security issues should be reported privately to the repository owner
until a dedicated security contact is configured.
