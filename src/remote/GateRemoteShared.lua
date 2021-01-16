-- Legend26

local module = {
	ServerEventType = {
		GateChanged = 1;
		GateStateUpdate = 2;
	};

	ClientEventType = {
		Ready = 1;
		Dial = 2;
	};

	GateState = {
		Idle = 1;
		Busy = 2;
		Disabled = 3;
		Dialing = 4;
		Incoming = 5;
		Outgoing = 6;
		OutgoingBlocked = 7;
	};
}

return module