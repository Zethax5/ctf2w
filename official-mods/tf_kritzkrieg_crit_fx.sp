#pragma semicolon 1
#include <sourcemod>

#include <tf2_stocks>

#pragma newdecls required

#include <stocksoup/tf/tempents_stocks>
#include <stocksoup/log_server>

public void TF2_OnConditionAdded(int client, TFCond cond) {
	if (cond == TFCond_Kritzkrieged) {
		int healers = GetEntProp(client, Prop_Send, "m_nNumHealers");
		if(healers > 0)
		{
			for (int i = 1; i < MaxClients; i++)
			{
				if(!IsClientInGame(i) || !IsPlayerAlive(i))
					continue;
				if(i == client)
					continue;
				if(GetMediGunPatient(i) != client)
					continue;
				if(GetWeaponIndex(GetActiveWeapon(i)) == 35
					&& GetEntProp(GetActiveWeapon(i), Prop_Send, "m_bChargeRelease")) {
					CreateTimer(0.5, ApplyKritzBoostParticle, GetClientSerial(client),
						TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
					break;
				}
			}
		}
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

public static GetMediGunPatient(client)
{
	new wep = GetPlayerWeaponSlot(client, 1);
	if (wep == -1 || wep != GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")) return -1;
	new String:class[15];
	GetEdictClassname(wep, class, sizeof(class));
	if (StrContains(class, "tf_weapon_med", false)) return -1;
	return GetEntProp(wep, Prop_Send, "m_bHealing") ? GetEntPropEnt(wep, Prop_Send, "m_hHealingTarget") : -1;
}

public static GetWeaponIndex(weapon)
{
	if (weapon < 0 || weapon > 2049)return -1;
	return GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
}

public static GetActiveWeapon(client)
{
	if (!IsValidClient(client))return -1;
	if(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") > -1)
	{
		return GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	}
	else return -1;
}
