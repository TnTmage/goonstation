/// Viewing a player's notes
/datum/admins/proc/viewPlayerNotes(player)
	if (!player)
		return

	if(src.tempmin)
		logTheThing(LOG_ADMIN, usr, "tried to access the notes of [constructTarget(player,"admin")]")
		logTheThing(LOG_DIARY, usr, "tried to access the notes of [constructTarget(player,"diary")]", "admin")
		message_admins("[key_name(usr)] tried to access the notes of [player] but was denied.")
		alert("You need to be an actual admin to view player notes.")
		del(usr.client)
		return

	var/datum/apiModel/Paginated/PlayerNoteResourceList/playerNotes
	try
		var/datum/apiRoute/players/notes/get/getPlayerNotes = new
		getPlayerNotes.queryParams = list(
			"filters" = list(
				"ckey" = player
			)
		)
		playerNotes = apiHandler.queryAPI(getPlayerNotes)
	catch (var/exception/e)
		var/datum/apiModel/Error/error = e.name
		logTheThing(LOG_DEBUG, null, "viewPlayerNotes: Failed to fetch notes of player: [player] because: [error.message]")
		alert("Failed to fetch notes for [player].")
		return

	var/datum/player/pdatum = make_player(player)
	pdatum.cloudSaves.fetch()
	var/noticelink = ""
	if (pdatum.cloudSaves.getData("login_notice"))
		noticelink = {" style="color: red; font-weight: bold;">Login Notice Set"}
	else
		noticelink = {">Add Login Notice"}

	var/list/dat = list({"
		<title>Player Notes - [player]</title>
		<style>
			body { background: #101018; color: #fff; font-family: Verdana, sans-serif; }
			table { width: 100%; border-spacing: 1px; }
			a { color: #88f; }
			th { background: #558; padding: 0.1em 0.25em; }
			td { background: #223; padding: 0.25em 0.5em; }
			.auto th { background: #446; color: #eee; }
			.auto td { background: #112; color: #aaa; }
			.ban th { background: #855; }
			.ban td { background: #633; }
			.auto.ban th { background: #644; }
			.auto.ban td { background: #311; }
			.empty td { padding: 0.25em; background: none;}
			blockquote { font-style: italic; margin: 0.3em 0 0.3em 3em; }
		</style>
		"})

	dat += "<h1 style='text-align: center;'>Player Notes for <b>[player]</b></h1><center><a href='?src=\ref[src];action=notes2;target=[player];type=add'>Add Note</A> - <a href='?src=\ref[src];action=loginnotice;target=[player]'[noticelink]</a></center><br><br><table><tbody>"

	if (!length(playerNotes.data))
		dat += "No notes. <i>Yet.</i>"

	else
		for (var/datum/apiModel/Tracked/PlayerNoteResource/playerNote in playerNotes.data)
			var/list/row_classes = list()
			var/noteReason = playerNote.note

			if (playerNote.game_admin.ckey == "bot")
				row_classes += "auto"

			var/regex/R = new("Banned from (.+?) by (.+?), reason: (.+), duration: (.+)", "m")
			if (R.Find(noteReason))
				row_classes += "ban"
				noteReason = R.Replace(noteReason, "<b>BANNED</b> from <b>$1</b> by <b>$2</b> &mdash; $4<br><blockquote>$3</blockquote>")

			var/classes = row_classes.Join(" ")
			dat += {"
			<tr class="[classes]">
				<th>[playerNote.server_id]</th>
				<th>[playerNote.created_at]</th>
				<th style='width: 0; white-space: pre;'>#[playerNote.id] <a href="?src=\ref[src];action=notes2;target=[player];type=del;id=[playerNote.id]" style="background: red; color: white; display: inline-block; text-align: center; padding: 0.1em 0.25em; border-radius: 4px; text-decoration: none;">&times;</a></th>
			</tr>
			<tr class="[classes]" style="margin-bottom: 1em;">
				<th>[playerNote.game_admin.ckey]</th>
				<td colspan="2" style="white-space: pre-wrap;">[noteReason]</td>
			</tr>
			<tr class='empty'><td colspan='3'></td></tr>
			"}

		dat += "</table>"

	usr.Browse(dat.Join(""), "window=notesp;size=875x600;title=Notes for [player]")


/// Adding a player note
/proc/addPlayerNote(player, admin, note)
	if (!player || !admin || !note)
		return

	try
		var/datum/apiRoute/players/notes/post/addPlayerNote = new
		addPlayerNote.buildBody(
			admin,
			roundId,
			config.server_id,
			player,
			note
		)
		apiHandler.queryAPI(addPlayerNote)
	catch (var/exception/e)
		var/datum/apiModel/Error/error = e.name
		logTheThing(LOG_DEBUG, null, "addPlayerNote: Failed to add note to player: [player] because: [error.message].")


/// Deleting a player note
/proc/deletePlayerNote(id)
	if (!id)
		return

	try
		var/datum/apiRoute/players/notes/delete/deletePlayerNote = new
		deletePlayerNote.routeParams = list("[id]")
		apiHandler.queryAPI(deletePlayerNote)
	catch (var/exception/e)
		var/datum/apiModel/Error/error = e.name
		logTheThing(LOG_DEBUG, null, "deletePlayerNote: Failed to delete note #[id] because: [error.message].")
