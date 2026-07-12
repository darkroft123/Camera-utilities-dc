import funkin.backend.utils.DiscordUtil;
import funkin.backend.utils.WindowUtils;

function onGameOver() {
	DiscordUtil.changePresence('Game Over', PlayState.SONG.meta.displayName + " (" + PlayState.difficulty + ")");
}

function onDiscordPresenceUpdate(e) {
	var data = e.presence;

	if(data.button1Label == null)
		data.button1Label = "Codename Engine Discord";
	if(data.button1Url == null)
		data.button1Url = "https://discord.gg/ZVauSD5pdC";
}

function onPlayStateUpdate() {
	DiscordUtil.changeSongPresence(
		PlayState.instance.detailsText,
		(PlayState.instance.paused ? "Paused - " : "") + PlayState.SONG.meta.displayName + " (" + PlayState.difficulty + ")",
		PlayState.instance.inst,
		PlayState.instance.getIconRPC()
	);
}

function onMenuLoaded(name:String) {
	DiscordUtil.changePresenceSince("In the Menus", null);

}

function onEditorTreeLoaded(name:String) {
	switch(name) {
		case "Character Editor":
			DiscordUtil.changePresenceSince("Choosing a Character", null);
		case "ModchartEditor":
			DiscordUtil.changePresenceSince("Choosing a Modchart", null);
		case "Chart Editor":
			DiscordUtil.changePresenceSince("Choosing a Chart", null);
		case "Stage Editor":
			DiscordUtil.changePresenceSince("Choosing a Stage", null);
	}
}

function onEditorLoaded(name:String, editingThing:String) {
	switch(name) {
		case "Character Editor":
			DiscordUtil.changePresenceSince("Editing a Character", editingThing);
		case "Chart Editor":
			DiscordUtil.changePresenceSince("Editing a Chart", editingThing);
		case "ModchartEditor":
			DiscordUtil.changePresenceSince("Editing a Modchart", editingThing);
		case "Stage Editor":
			DiscordUtil.changePresenceSince("Editing a Stage", editingThing);
	}
}