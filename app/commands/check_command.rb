# CheckCommand handles the `/deploy check` command.
class CheckCommand < BaseCommand
  def run
    transaction do
      repo = Repository.with_name(params['repository'])
      return Slash.reply(ValidationErrorMessage.build(record: repo)) if repo.invalid?

      env = repo.environment(params['environment'])
      return Slash.reply(EnvironmentsMessage.build(repository: repo)) unless env
      return Slash.reply(ValidationErrorMessage.build(record: env)) if env.invalid?

      Slash.say CheckMessage.build \
        environment: env,
        slack_team: account.slack_team
    end
  end
end
