// #define DECLARE_BASE_MESSAGE( msgtype )
// 	public:
// 		bool			ReadFromBuffer( bf_read &buffer );
// 		bool			WriteToBuffer( bf_write &buffer );
// 		const char		*ToString() const;
// 		int				GetType() const { return msgtype; }
// 		const char		*GetName() const { return #msgtype;}
// #define DECLARE_CLC_MESSAGE( name )
// 	DECLARE_BASE_MESSAGE( clc_##name );
// 	IClientMessageHandler *m_pMessageHandler;
// 	bool Process() { return m_pMessageHandler->Process##name( this ); }
// class CLC_ClientInfo : public CNetMessage
// {
// 	DECLARE_CLC_MESSAGE( ClientInfo );

// public:
// 	CRC32_t			m_nSendTableCRC;
// 	int				m_nServerCount;
// 	bool			m_bIsHLTV;
// #if defined( REPLAY_ENABLED )
// 	bool			m_bIsReplay;
// #endif
// 	uint32			m_nFriendsID;
// 	char			m_FriendsName[MAX_PLAYER_NAME_LENGTH];
// 	CRC32_t			m_nCustomFiles[MAX_CUSTOM_FILES];
// };

const std = @import("std");

pub const ClientInfo = struct {};
