pub const DemoError = error{
    EarlyTermination,
    LibcFread,
    BadHeader,
    Corruption,
    InvalidDemoMessage,
    NotEnoughMemory,
    FileDoesNotMatchPromised,
    BadNetworkControlCommand,
};
