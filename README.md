# libdemo

Library for reading Team Fortress 2 demo files.

## MegaAntiCheat Dependent

[MegaAntiCheat](https://github.com/MegaAntiCheat) is (potentially) dependent on
this TF2 demo file implementation. That means that I plan on adding features in
the order of priority for that project.

Here are the planned features which are necessary for MAC, not in any particular
order.

- [ ] Player identity: ``CTFPlayerResource`` in the TF2 source code, "UserInfo" in
[demostf/parser](https://github.com/demostf/parser)
- [ ] Entity ID
- [ ] Player ID
- [ ] Steam ID
- [ ] Team: ``CTFPlayerResource.m_iTeam``
- [ ] Player entity: ``CTFPlayer``
- [ ] Life state: ``DT_BasePlayer.m_lifeState`` (byte)
- [ ] Origin: ``DT_TF(Non)LocalPlayerExclusive.m_vecOrigin`` (vec3)
- [ ] View angles: ``DT_TF(Non)LocalPlayerExclusive.m_angEyeAngles`` (vec2)
- [ ] Simulation time - ``DT_BaseEntity.m_flSimulationTime`` (int)
- [ ] Duck amount (untested) - ``DT_BasePlayer.m_flDucktime`` (float)
- [ ] Flags (untested) - ``DT_BasePlayer.m_fFlags`` (int)
- [ ] ``player_hurt`` event:
  - [ ] Victim - userid
  - [ ] Attacker - attacker
  - [ ] Weapon ID - weaponid
  - [ ] Damage done - damageamount
