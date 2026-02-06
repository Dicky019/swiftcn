import {
  GitServiceImpl,
  FileServiceImpl,
  RegistryServiceImpl,
  ConfigServiceImpl,
  FetcherServiceImpl,
  type GitService,
  type FileService,
  type RegistryService,
  type ConfigService,
  type FetcherService,
} from "./services/index.js";

export interface Container {
  git: GitService;
  file: FileService;
  registry: RegistryService;
  config: ConfigService;
  fetcher: FetcherService;
}

export function createContainer(): Container {
  const git = new GitServiceImpl();
  const file = new FileServiceImpl();
  const registry = new RegistryServiceImpl(file);
  const config = new ConfigServiceImpl(file);
  const fetcher = new FetcherServiceImpl(git, file, registry);

  return { git, file, registry, config, fetcher };
}

export function createTestContainer(
  overrides: Partial<Container> = {}
): Container {
  const base = createContainer();
  return { ...base, ...overrides };
}
