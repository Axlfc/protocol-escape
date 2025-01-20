# Protocol-Escape Game

*A Modular VR Escape Game*  

---

## About the Game

**Protocol-Escape Game** is a virtual reality (VR) escape room game built using the [LÖVR](https://lovr.org/) framework and Lua scripting. As an indie developer, I, **Axlfc**, designed this game to provide an immersive and extensible VR experience, packed with intriguing puzzles and a modular architecture for scalability.

---

## Features

- 🎮 **Rich VR Interactivity**: Supports multiple VR platforms for a fully immersive escape room experience.
- 🛠️ **Modular Design**: Decoupled game components allow for easy expansion and maintenance.
- 🔥 **Custom Rendering**: Advanced graphics powered by LÖVR's shader system.
- 📊 **Data-Driven Menus**: Easily update menus and UI without diving into the code.
- ⚙️ **Physics-Based Gameplay**: Realistic interactions and puzzles.

---

## Architecture

The game's architecture is organized into several components:

1. **Core**
    - `main.lua`: Entry point managing the game lifecycle.
2. **Controllers**
    - `sceneManager.lua`: Handles scenes and transitions.
    - `gameController.lua`: Manages game logic and player actions.
3. **Models**
    - `gameState.lua`, `playerState.lua`: Track game and player states.
4. **Views**
    - `menuView.lua`, `hud.lua`: Render UI and HUD components.
5. **Entities**
    - `pawn.lua`, `character.lua`: Represent objects and players in the game.
6. **Utilities**
    - `eventDispatcher.lua`, `logger.lua`: Support debugging and event handling.

---

## Getting Started

### Prerequisites
- Lua installed (source)
- A VR headset (optional for development).

### Installation
1. Clone this repository:
   ```bash
   git clone https://github.com/axlfc/protocol-escape-game.git
   cd protocol-escape-game
   ```
2. Extract [LÖVR](https://lovr.org/) files in the repository.

3. Run the project:
   - Windows:
     ```bash
       .\lovr.exe .
     ```
     **or drag-and-drop the main.lua file onto lovr.exe or lovrc.bat**
   - macOS/Linux:
     ```bash
       lovr .
     ```

---

## Controls

- **Interact**: Press the trigger on your VR controller.
- **Move**: Use the thumbstick or trackpad.
- **Menu**: Access with the menu button.

---

## Contact
Follow me, **Axlfc**, on:
- [GitHub](https://github.com/axlfc)

---

Happy coding! 🚀
