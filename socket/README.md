# Real-time Socket Layer

The production architecture should use Socket.IO with rooms:

- `join-room`
- `chat-message`
- `whiteboard-draw`
- `whiteboard-clear`
- `quiz-score`

Example event payload:
```json
{"roomId":"python-ai","type":"line","x":120,"y":80,"prevX":110,"prevY":75}
```

Keep this logic isolated from normal REST APIs so it can scale independently.
