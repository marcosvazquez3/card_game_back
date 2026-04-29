import { Socket, Presence } from "phoenix";

class ChatClient {
  constructor(userToken, options = {}) {
    this.userToken = userToken;
    this.socket = null;
    this.channel = null;
    this.presence = null;
    this.callbacks = {};
    this.typingTimeout = null;
    this.isTyping = false;

    // Merge default options
    this.options = {
      onMessage: () => {},
      onPresenceChange: () => {},
      onTyping: () => {},
      onError: () => {},
      ...options,
    };
  }

  connect() {
    this.socket = new Socket("/socket", {
      params: { token: this.userToken },
    });

    this.socket.onError(() => {
      this.options.onError("Connection error");
    });

    this.socket.connect();
    return this;
  }

  joinRoom(roomId, lastSeenId = 0) {
    return new Promise((resolve, reject) => {
      // Leave current channel if any
      if (this.channel) {
        this.channel.leave();
      }

      this.channel = this.socket.channel(`chat:${roomId}`, {
        last_seen_id: lastSeenId,
      });

      // Set up presence tracking
      this.presence = new Presence(this.channel);
      this.presence.onSync(() => {
        const users = this.presence.list((id, { metas: [first] }) => ({
          id,
          ...first,
        }));
        this.options.onPresenceChange(users);
      });

      // Handle incoming messages
      this.channel.on("message", (msg) => {
        this.options.onMessage(msg);
      });

      // Handle typing indicators
      this.channel.on("typing_start", ({ user_id, username }) => {
        this.options.onTyping({ userId: user_id, username, isTyping: true });
      });

      this.channel.on("typing_stop", ({ user_id }) => {
        this.options.onTyping({ userId: user_id, isTyping: false });
      });

      // Handle reactions
      this.channel.on("reaction_added", (data) => {
        if (this.options.onReaction) {
          this.options.onReaction(data);
        }
      });

      // Join the channel
      this.channel
        .join()
        .receive("ok", (response) => {
          resolve(response);
        })
        .receive("error", (response) => {
          reject(new Error(response.reason));
        })
        .receive("timeout", () => {
          reject(new Error("Connection timeout"));
        });
    });
  }

  sendMessage(body) {
    return new Promise((resolve, reject) => {
      this.channel
        .push("message", { body })
        .receive("ok", resolve)
        .receive("error", reject)
        .receive("timeout", () => reject(new Error("Timeout")));
    });
  }

  // Debounced typing indicator
  sendTyping() {
    if (!this.isTyping) {
      this.isTyping = true;
      this.channel.push("typing_start", {});
    }

    // Clear existing timeout
    if (this.typingTimeout) {
      clearTimeout(this.typingTimeout);
    }

    // Stop typing after 2 seconds of no input
    this.typingTimeout = setTimeout(() => {
      this.isTyping = false;
      this.channel.push("typing_stop", {});
    }, 2000);
  }

  addReaction(messageId, emoji) {
    this.channel.push("react", { message_id: messageId, emoji });
  }

  loadMoreMessages(beforeId) {
    return new Promise((resolve, reject) => {
      this.channel
        .push("load_more", { before_id: beforeId })
        .receive("ok", ({ messages }) => resolve(messages))
        .receive("error", reject);
    });
  }

  leaveRoom() {
    if (this.channel) {
      this.channel.leave();
      this.channel = null;
      this.presence = null;
    }
  }

  disconnect() {
    this.leaveRoom();
    if (this.socket) {
      this.socket.disconnect();
    }
  }
}

// Usage example
const chat = new ChatClient(window.userToken, {
  onMessage: (msg) => {
    appendMessage(msg);
  },
  onPresenceChange: (users) => {
    updateOnlineUsers(users);
  },
  onTyping: ({ username, isTyping }) => {
    updateTypingIndicator(username, isTyping);
  },
});

chat.connect();

chat.joinRoom("general").then((response) => {
  // response.messages contains recent messages
  response.messages.forEach(appendMessage);
});