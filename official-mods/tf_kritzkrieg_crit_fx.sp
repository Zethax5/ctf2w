#pragma semicolon 1
#include <sourcemod>

#include <tf2_stocks>

#pragma newdecls required

#include <stocksoup/tf/tempents_stocks>
#include <stocksoup/log_server>

public void TF2_OnConditionAdded(int client, TFCond cond) {
	if (cond == TFCond_Kritzkrieged) {
		CreateTimer(0.5, ApplyKritzBoostParticle, GetClientSerial(client),
				TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action ApplyKritzBoostParticle(Handle timer, int clientserial) {
	int client = GetClientFromSerial(clientserial);
	
	if (!client) {
		return Plugin_Stop;
	}
	
	if (!TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged)) {
		return Plugin_Stop;
	}
	
	int hActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(hActiveWeapon)) {
		return Plugin_Continue;
	}
	
	TE_SetupTFParticleEffect(TF2_GetClientTeam(client) == TFTeam_Red?
			"electrocuted_gibbed_red" : "electrocuted_gibbed_blue", NULL_VECTOR,
			.entity = hActiveWeapon, .attachType = PATTACH_ABSORIGIN, .bResetParticles = false);
	TE_SendToAll();
	
	return Plugin_Continue;
}
