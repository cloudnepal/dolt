package sysbench_runner

type ServerType string

type ServerConfig interface {
	GetId() string
	GetHost() string
	GetPort() int
	GetVersion() string
	GetServerExec() string
	GetResultsFormat() string
	GetServerType() ServerType
	GetServerArgs() ([]string, error)
	GetTestingParams(testConfig TestConfig) TestParams
	Validate() error
	SetDefaults() error
}

type InitServerConfig interface {
	ServerConfig
	GetInitDbExec() string
}

type ProtocolServerConfig interface {
	ServerConfig
	GetConnectionProtocol() string
	GetSocket() string
}

type ProfilingServerConfig interface {
	ServerConfig
	GetServerProfile() ServerProfile
	GetProfilePath() string
}
