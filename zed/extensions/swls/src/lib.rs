use zed_extension_api as zed;

struct SwlsExtension;

impl zed::Extension for SwlsExtension {
    fn new() -> Self {
        Self
    }

    fn language_server_command(
        &mut self,
        _server_id: &zed::LanguageServerId,
        worktree: &zed::Worktree,
    ) -> zed::Result<zed::Command> {
        let command = worktree
            .which("swls")
            .ok_or_else(|| "The swls executable was not found in PATH".to_string())?;

        Ok(zed::Command {
            command,
            args: Vec::new(),
            env: Default::default(),
        })
    }
}

zed::register_extension!(SwlsExtension);
