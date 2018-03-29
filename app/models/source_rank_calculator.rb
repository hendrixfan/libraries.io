class SourceRankCalculator
  def initialize(project)
    @project = project
  end

  def overall_score
    overall_scores.values.sum/overall_scores.values.length.to_f
  end

  def popularity_score
    popularity_scores.values.sum/popularity_scores.values.length.to_f
  end

  def community_score
    community_scores.values.sum/community_scores.values.length.to_f
  end

  def quality_score
    quality_scores.values.sum/quality_scores.values.length.to_f
    # multiple_versions_present
    # follows_semver
    # one_point_oh
    # all_prereleases

    # any_outdated_dependencies
    # direct_dependencies_score
  end

  def breakdown
    {
      popularity: popularity_scores,
      community: community_scores,
      quality: quality_scores
    }
  end

  def basic_info_score
    basic_info.values.select{|v| v}.length/basic_info.values.length.to_f*100
  end

  def contribution_docs_score
    contribution_docs.values.select{|v| v}.length/contribution_docs.values.length.to_f*100
  end

  def dependent_projects_score
    return 0 if max_dependent_projects.to_f.zero?
    @project.dependents_count/max_dependent_projects.to_f*100
  end

  def dependent_repositories_score
    return 0 if max_dependent_repositories.to_f.zero?
    @project.dependent_repos_count/max_dependent_repositories.to_f*100
  end

  def stars_score
    return 0 if max_stars.to_f.zero?
    @project.stars/max_stars.to_f*100
  end

  def forks_score
    return 0 if max_forks.to_f.zero?
    @project.forks/max_forks.to_f*100
  end

  def watchers_score
    return 0 if max_watchers.to_f.zero?
    @project.watchers/max_watchers.to_f*100
  end

  def status_score
    inactive_statuses.include?(@project.status) ? 0 : 100
  end

  def recent_releases_score
    return 0 unless @project.published_releases.length > 0
    @project.published_releases.any? {|v| v.published_at && v.published_at > 6.months.ago } ? 100 : 0
  end

  def brand_new_score
    return 0 unless @project.published_releases.length > 0
    @project.published_releases.any? {|v| v.published_at && v.published_at < 6.months.ago } ? 100 : 0
  end

  def contributors_score
    return 0 if @project.contributions_count < 2
    return 100 if @project.contributions_count > 5
    50
  end

  def maintainers_score
    return 0 if @project.registry_users.count < 2
    return 100 if @project.registry_users.count > 5
    50
  end

  private

  def inactive_statuses
    ["Deprecated", "Removed", "Unmaintained", "Hidden"]
  end

  def max_dependent_projects
    @max_dependent_projects ||= (Project.platform(@project.platform)
                                        .order('dependents_count DESC NULLS LAST')
                                        .limit(1)
                                        .pluck(:dependents_count)
                                        .first || 0)
  end

  def max_dependent_repositories
    @max_dependent_repositories ||= (Project.platform(@project.platform)
                                            .order('dependent_repos_count DESC NULLS LAST')
                                            .limit(1)
                                            .pluck(:dependent_repos_count)
                                            .first || 0)
  end

  def max_stars
    @max_stars ||= (Project.platform(@project.platform)
                           .joins(:repository)
                           .order('repositories.stargazers_count DESC NULLS LAST')
                           .limit(1)
                           .pluck(:stargazers_count)
                           .first || 0)
  end

  def max_forks
    @max_forks ||= (Project.platform(@project.platform)
                           .joins(:repository)
                           .order('repositories.forks_count DESC NULLS LAST')
                           .limit(1)
                           .pluck(:forks_count)
                           .first || 0)
  end

  def max_watchers
    @max_watchers ||= (Project.platform(@project.platform)
                           .joins(:repository)
                           .order('repositories.subscribers_count DESC NULLS LAST')
                           .limit(1)
                           .pluck(:subscribers_count)
                           .first || 0)
  end

  def popularity_scores
    {
      dependent_projects: dependent_projects_score,
      dependent_repositories: dependent_repositories_score,
      stars: stars_score,
      forks: forks_score,
      watchers: watchers_score
    }
  end

  def quality_scores
    {
      basic_info: basic_info_score,
      status: status_score
    }
  end

  def community_scores
    {
      contribution_docs: contribution_docs_score,
      recent_releases: recent_releases_score,
      brand_new: brand_new_score,
      contributors: contributors_score,
      maintainers: maintainers_score
    }
  end

  def basic_info
    {
      description:    @project.description.present?,
      homepage:       @project.homepage.present?,
      repository_url: @project.repository_url.present?,
      keywords:       @project.keywords.present?,
      readme:         @project.readme.present?,
      license:        @project.normalized_licenses.present?
    }
  end

  def contribution_docs
    {
      code_of_conduct: @project.has_coc.present?,
      contributing:    @project.has_contributing.present?,
      changelog:       @project.has_changelog.present?
    }
  end

  def overall_scores
    {
      popularity: popularity_score,
      community: community_score,
      quality: quality_score
    }
  end
end
