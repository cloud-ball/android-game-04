extends Node
## The single soft currency (coins), shared by every game.

signal coins_changed(total: int)


func coins() -> int:
	return int(SaveService.data["economy"].get("coins", 0))


func add_coins(amount: int) -> void:
	if amount == 0:
		return
	var total := maxi(0, coins() + amount)
	SaveService.data["economy"]["coins"] = total
	SaveService.save()
	coins_changed.emit(total)
