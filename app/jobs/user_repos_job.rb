class UserReposJob < ActiveJob::Base
  queue_as :git

  attr_accessor :user

  rescue_from(StandardError) do |exception|
    user.set(last_repo_sync_at: nil) if user
  end

  def perform(user)
    return if user.repo_syncing?
    user.set(last_repo_sync_at: Time.now)
    @user = user

    gh_repos = user.fetch_all_github_repos

    gh_repos.each do |gh_repo|
      add_repo(gh_repo)
    end
  end

  def add_repo(gh_repo)
    #check if the repository is not soft deleted and
    repo = Repository.unscoped.where(gh_id: gh_repo.id).first

    if repo
      if repo.info.stargazers_count < REPOSITORY_CONFIG['popular']['stars']
        # soft delete the repository if the star rating has declined.
        repo.destroy
      else
        # restore the repo if the repository was already soft deleted and the current star count is greater then the threshold
        repo.restore if repo.destroyed?
      end

      repo.users << user unless repo.users.include?(user)
      return
    end

    repo = Repository.build_from_gh_info(gh_repo)

    if repo.stars >= REPOSITORY_CONFIG['popular']['stars']
      user.repositories << repo
      user.save
      return
    end

    return unless gh_repo.fork
    return if repo.info.source.stargazers_count < REPOSITORY_CONFIG['popular']['stars']

    repo.popular_repository = repo.create_popular_repo
    repo.source_gh_id = repo.info.source.id
    user.repositories << repo
    user.save
  end
end
