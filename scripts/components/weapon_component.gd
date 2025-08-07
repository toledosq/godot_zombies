class_name WeaponComponent extends InventoryComponent

signal active_weapon_changed(slot_idx: int, weapon: WeaponData)
signal request_ammo(type: String, amount: int)
signal reload_started
signal reload_complete

@export var active_slot: int = 0
@export var combat_component: Node3D
@export var auto_reload: bool = false

var can_change_active_slot := true
var can_reload := true
var can_fire := true

# Store ref to active weapon to make code easier to read
var active_slot_weapon: WeaponData


func _ready() -> void:
	self.connect("item_added", _on_item_added)
	self.connect("item_removed", _on_item_removed)
	inventory.max_slots = max_slots

func set_active_slot(idx: int) -> void:
	if can_change_active_slot:
		if idx < 0 or idx >= max_slots:
			return
		print("WeaponComponent: Switching active slot from %d to %d" % [active_slot, idx])
		active_slot = idx
		update_active_slot()
	else:
		print("WeaponComponent: Cannot change active weapon right now")

func update_active_slot() -> void:
	var w = inventory.slots[active_slot]
	active_slot_weapon = w.item
	emit_signal("active_weapon_changed", active_slot, active_slot_weapon)

func _on_item_added(idx: int, _item: ItemData, _qty: int) -> void:
	if idx == active_slot:
		print("WeaponComponent: Weapon equipped in active slot (%d | %d)" % [idx, active_slot])
		update_active_slot()

func _on_item_removed(idx: int, _item: ItemData, _qty: int) -> void:
	if idx == active_slot:
		print("WeaponComponent: Weapon unequipped in active slot (%d | %d)" % [idx, active_slot])
		update_active_slot()

## OVERRIDE ADD_ITEM TO ALLOW CUSTOM BEHAVIOR
func add_item(item: ItemData, quantity: int = 1) -> Dictionary:
	if not item is WeaponData:
		push_warning("WeaponComponent: only accepts WeaponData")
		var result = {
			"added": 0,		 # how many items went in
			"rejected": quantity  # leftovers
		}
		return result
	
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
		print("WeaponComponent: slot members: ", inventory.print_slot_members())
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
	print("WeaponComponent: Requesting %d %s from player inventory" % [amount, active_slot_weapon.ammo_type])
	#var received = player_inventory.request_ammo(ItemDatabase.get_item(active_slot_weapon.ammo_type), amount)
	request_ammo.emit(active_slot_weapon.ammo_type, amount)


func _on_received_ammo(received: int) -> void:
	# If no ammo, return early
	if received == 0:
		print("WeaponComponent: Did not recieve ammo, aborting reload")
		can_change_active_slot = true
		can_reload = true
		can_fire = true
		return
	
	# Send noti that reload is occuring
	print("WeaponComponent: Received ammo - amount: %d" % received)
	reload_started.emit() 
	
	# Add reload timer here
	
	# Add ammo to weapon magazine
	active_slot_weapon.current_ammo += received
	
	# Reload finished, allow changing active slots
	reload_complete.emit()
	print("WeaponComponent: Reload complete - %d/%d" % [active_slot_weapon.current_ammo, active_slot_weapon.mag_size])
	can_change_active_slot = true
	can_reload = true
	can_fire = true


func try_attack() -> bool:
	print("WeaponComponent: Trying to attack")
	
	# Check if we can fire
	if not can_fire:
		return false
	
	# Check if there is an active weapon
	# TODO: Eventually there will need to be an unarmed melee attack
	if not active_slot_weapon:
		print("WeaponComponent: Active slot is empty - unarmed attack")
		inventory.print_slot_members()
		can_fire = false
		# TODO: Implement Rate of Fire delay here w/ timer
		combat_component.attack_melee()
		can_fire = true
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
		print("WeaponComponent: Cannot attack - weapon empty")
		if auto_reload:
			reload_weapon() # TODO: threaded call?
		return false
		
	# If ranged weapon and mag not empty
	else:
		print("WeaponComponent: Calling combat component.attack_ranged")
		can_fire = false
		combat_component.attack_ranged()
		# TODO: Implement Rate of Fire delay here w/ timer
		active_slot_weapon.current_ammo -= 1
		print("WeaponComponent: Ammo remaining: %d/%d" % [active_slot_weapon.current_ammo, active_slot_weapon.mag_size])
		can_fire = true
		return true
