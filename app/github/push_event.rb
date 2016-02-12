# Handles the push event from github.
class PushEvent < GithubEventHandler
  def run
    transaction do
      return unless environment
      slashdeploy.auto_deploy auto_deployment
    end
  end

  private

  # The git commit sha to deploy
  def sha
    event['head_commit']['id']
  end

  # Returns the environment that's configured to auto deploy this git ref.
  def environment
    @environment = repository.auto_deploy_environment_for_ref(event['ref'])
  end

  # Returns the user that should be attributed with the deployment. This will
  # be the user that pushed to GitHub if we know who they are in SlashDeploy.
  def deployer
    @deployer ||= begin
                    account = GithubAccount.find_by(id: event['sender']['id'])
                    return environment.auto_deploy_user unless account
                    account.user
                  end
  end

  def auto_deployment
    @auto_deployment ||= begin
                           existing = environment.active_auto_deployment
                           if existing
                             # This can happen if the user triggers the webhook manually.
                             return existing if existing.sha == sha

                             # If this environment has an existing active auto deployment, we'll
                             # cancel it before starting this auto deployment. We do this to prevent
                             # race conditions where commit status events for an older auto deployment
                             # could come in late.
                             existing.cancel!
                           end
                           environment.auto_deployments.create! user: deployer, sha: sha
                         end
  end
end
