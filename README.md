# Roomy

Roomy is a virtual space to get together with people.

The idea is to have a virtual space where people can talk by voice and text and can interact with smart objects placed
around the room.

[![](http://img.youtube.com/vi/eVxHZpLzVUc/0.jpg)](http://www.youtube.com/watch?v=eVxHZpLzVUc "Roomy Demo")

What is already implemented:

- Basic tile-based 2d "game" environment:
  - Tiles for rendering
  - "Walkable" map to determine the tiles where the participant can walk
  - Collision between participants so you cannot walk into another participant
- Video Chat with volume based on participant position
- TV smart object:
  - Anyone can open and "watch" the TV.
  - Only those next to the TV can change the channel, turn on or off the TV
- TicTacToe game "board"

Other things that we have in mind but were left out:

- Text Chat
- Speed moviment control
- Keep moving when key is still pressed
- Multiple rooms with room creation form
- User authentication
- Persistent player position

## Running

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Testing

Run `mix check`