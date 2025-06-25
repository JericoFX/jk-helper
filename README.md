# JK-Helper

this is just a modification of the v1 with modules.

A complete solution for that kind of people that dont want to jump from one resource to another to add or modify something.
Job Menu Creator

# Here you can Modify and create:

    Boss Menu 
    Stash to store items (Shared) – configure slots & max weight per stash
    Cloth Coords (vector3)
    Blip Creator
    Garage to take Vehicles
        Take vehicle Coords (vector3)
        Menu's Title
        A list of vehicles to take.
        Optional livery table.
        Separate points for menu, store vehicle and delete vehicle.
        Custom return / delete coords.
        Return Coords (vector3)
        Spawn Coords (VECTOR4)
        Delete Coords (vector3)
        Livery config.
    Shop Creator
        Name of the Shop
        Inventory with name-price-amount configurable via JSON when creating.
        Locations (Array of vector3)

Example: Short one, whitout a lot of stuff

### Database integration (v0.1)

• All job points are now stored in the database (tables `jk_jobs` & `jk_job_points`).
• Foreign-key relation with `ON DELETE/UPDATE CASCADE` keeps data consistent.
• Resource creates the tables automatically on first run; no manual SQL needed.

### Admin tools

• Command **/jkcreatepoint** (default key **F7**) opens a simple ox_lib dialog.
  – First, look at the ground where you want the point and press **E**. A cyan marker shows the hit position in real-time.
  – After selecting the position, a dialog asks for:
    • Job name
    • Point type (stash, privateStash, duty, shop, garage, boss, cloth)
    • Minimum grade allowed (defaults to 0)
    • Label
    • Blip sprite & color (sprite 0 = no blip)
• After confirmation the point is stored in the database and instantly synced to all players.

Future versions will include point editing & deletion from the same interface.

### Manage existing points

• Command **/jkmanagepoints** (key **F9**) open the menu with all points created.

### Stash & Private Stash
• When adding a point choose *Slots* and *Max Weight*

### Garage
• When creating a garage, you'll be prompted to select 4 different points:
  1. **Main Menu Position**: Where players open the vehicle selection menu
  2. **Spawn Point**: Where vehicles appear when selected from menu  
  3. **Return Point**: Where players go to save/store their vehicles
  4. **Police Menu Point**: Additional point for police-specific interactions
• For each vehicle, specify the label, model/hash, and optional livery.
• **Security Features**:
  - Job validation: Only players with the correct job can access garage functions
  - Grade validation: Minimum grade requirements are enforced
  - Server-side validation: Double-check on server for all garage operations
  - Plate tracking: Server tracks vehicle ownership and validates returns
  - CPU optimization: Text prompts only show for authorized players
• If something goes wrong, admins can run **/releaseplate JK123456** to manually free a plate.

### Shop
• Add items one by one with three fields per item:
  - **Item Name**: The item identifier (must exist in ox_inventory)
  - **Amount**: Quantity available (0 = unlimited stock)  
  - **Price**: Cost per item (0 = free item)
• Items with amount or price set to 0 will ignore those constraints.

### Vehicle Helper Functions
• **Vehicle.setExtras(vehicle, extras)**: Set vehicle extras/livery client-side
• **Vehicle.setExtrasSecure(vehicle, extras)**: Set vehicle extras with server validation
• **Vehicle.spawn(model, coords, job, grade, callback)**: Server-side vehicle spawning with validation
• **Vehicle.getType(model)**: Automatic vehicle type detection for CreateVehicleServerSetter
• **jk-helper:server:spawnVehicle**: Secure server-side spawning using QBCore.Functions.SpawnVehicle
• Uses QBCore.Functions.SpawnVehicle for reliable vehicle creation with framework integration
• Automatic vehicle type detection (automobile, heli, plane, boat, bike, trailer, etc.)
• All functions support job and grade validation for enhanced security
• Server-side spawning provides better control, security, and networking

### Raycast Point Placement
Points are now placed where the camera crosshair hits the ground (10 m range). If the raycast fails it falls back to the player's current position.
