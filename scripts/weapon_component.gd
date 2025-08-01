class_name WeaponComponent extends InventoryComponent

signal active_weapon_changed(slot_idx: int, weapon: WeaponData)
signal reload_started
signal reload_complete

@export var active_slot: int = 0
@export var combat_component: Node3D
@export var player_inventory: InventoryComponent
@export var auto_reload: bool = true

var can_change_active_slot := true
var can_reload := true
var can_fire := true

# Store ref to active weapon to make code easier to read
var active_slot_weapon: WeaponData
#var active_slot_is_null := true
#var active_weapon_ranged: bool = false
#var active_weapon_current_ammo := 0
#var active_weapon_max_ammo := 0
#var active_weapon_ammo_type: String = ""

func set_active_slot(idx: int) -> void:
	if can_change_active_slot:
		if idx < 0 or idx >= max_slots:
			return
		active_slot = idx
		var w = inventory.slots[idx]
		active_slot_weapon = w.item
		emit_signal("active_weapon_changed", idx, w)
	else:
		print("WeaponComponent: Cannot change active weapon right now")

func _ready() -> void:
	inventory.max_slots = max_slots

func add_item(item: ItemData, quantity: int = 1) -> Dictionary:
	if not item is WeaponData:
		push_warning("WeaponComponent only accepts WeaponData")
		var result = {
			"added": 0,		 # how many items went in
			"rejected": quantity  # leftovers
		}
		return result
		
	# TODO: WeaponComponent needs to update the stored active_slot_weapon
	return super.add_item(item, quantity)

func reload_weapon() -> void:
	print("WeaponComponent: Attempting weapon reload")
	
	# Check if allowed to reload
	if not can_reload:
		print("WeaponComponent: Cannot reload - can_reload = false")
		return
		
	# Check if there is an active weapon
	if not active_slot_weapon:
		print("WeaponComponent: Cannot reload - active slot is empty")
		return
	
	# Check if ranged weapon
	if not active_slot_weapon.weapon_type == "ranged":
		print("WeaponComponent: Can't reload, active weapon is not ranged")
		return
		
	# Calculate how much ammo is needed
	var amount: int = active_slot_weapon.mag_size - active_slot_weapon.current_ammo
	
	# Check if mag is full
	if amount == 0:
		print("WeaponComponent: Cannot reload, magazine full")
		return
	
	# Don't let player change weapons during reload
	can_change_active_slot = false
	can_reload = false
	can_fire = false
	
	# Request ammo from player's inventory component
	print("WeaponComponent: Requesting %d %s from inventory" % [amount, active_slot_weapon.ammo_type])
	var received = player_inventory.request_ammo(ItemDatabase.get_item(active_slot_weapon.ammo_type), amount)

	# If no ammo, return early
	if received == 0:
		print("WeaponComponent: Did not recieve ammo, aborting reload")
		can_change_active_slot = true
		can_reload = true
		can_fire = true
		return
	
	# Send noti that reload is occuring
	print("WeaponComponent: Received ammo - amount: %d" % amount)
	reload_started.emit() 
	
	# Add reload timer here
	
	# Add ammo to weapon magazine
	active_slot_weapon.current_ammo += amount
	
	# Reload finished, allow changing active slots
	reload_complete.emit()
	can_change_active_slot = true
	can_reload = true
	can_fire = true


func try_fire() -> bool:
	print("WeaponComponent: Trying to fire")
	
	# Check if we can fire
	if not can_fire:
		return false
	
	# Check if there is an active weapon
	if not active_slot_weapon:
		print("WeaponComponent: Cannot fire, active slot is empty")
		return false
	
	# If melee weapon, just fire it off
	elif active_slot_weapon.weapon_type == "melee":
		
		can_fire = false
		# TODO: Implement Rate of Fire delay here w/ timer
		combat_component.attack_melee() # TODO: threaded call?
		can_fire = true
		return true
	
	# If ranged weapon, but mag empty
	elif active_slot_weapon.current_ammo <= 0:
		print("WeaponComponent: Cannot fire - weapon empty")
		if auto_reload:
			reload_weapon() # TODO: threaded call?
		return false
		
	# If ranged weapon and mag not empty
	else:
		can_fire = false
		combat_component.attack_ranged()
		# TODO: Implement Rate of Fire delay here w/ timer
		active_slot_weapon.current_ammo -= 1
		can_fire = true
		return true
