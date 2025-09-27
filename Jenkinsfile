properties(
    [
        githubProjectProperty(
            displayName: 'docker-socks5balancerasio',
            projectUrlStr: 'https://github.com/ruepp-jenkins/docker-socks5balancerasio'
        ),
        disableConcurrentBuilds(abortPrevious: true)
    ]
)

pipeline {
    agent {
        label 'docker'
    }

    environment {
        IMAGE_FULLNAME = 'ruepp/socks5balancerasio'
        DOCKER_API_PASSWORD = credentials('DOCKER_API_PASSWORD')
        TRIVY_TOKEN = credentials('TRIVY_TOKEN')
        DEPENDENCYTRACK_HOST = 'http://172.20.89.2:8080'
        DEPENDENCYTRACK_API_TOKEN = credentials('dependencychecker')
    }

    triggers {
        URLTrigger(
            cronTabSpec: 'H/30 * * * *',
            entries: [
                URLTriggerEntry(
                    url: 'https://hub.docker.com/v2/namespaces/library/repositories/alpine/tags/3.18',
                    contentTypes: [
                        JsonContent(
                            [
                                JsonContentEntry(jsonPath: '$.last_updated')
                            ]
                        )
                    ]
                ),
                URLTriggerEntry(
                    url: 'https://api.github.com/repos/Socks5Balancer/Socks5BalancerAsio/commits/master',
                    contentTypes: [
                        JsonContent(
                            [
                                JsonContentEntry(jsonPath: '$.commit.author.date')
                            ]
                        )
                    ]
                )
            ]
        )
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: env.BRANCH_NAME,
                url: env.GIT_URL
            }
        }
        stage('Build') {
            steps {
                sh 'chmod +x scripts/*.sh'
                sh './scripts/start.sh'
            }
        }
        stage('SBOM generation') {
            steps {
                sh "docker run --rm --network Internal -v /opt/docker/jenkins/jenkins_ws:/home/jenkins/workspace aquasec/trivy image --server http://172.20.89.4:4954 --token ${TRIVY_TOKEN} --format cyclonedx --output ${WORKSPACE}/bom.xml --scanners vuln,secret ${IMAGE_FULLNAME}:latest"
            }
        }
        stage('DependencyTracker') {
            steps {
                script {
                    // root project body
                    def body = groovy.json.JsonOutput.toJson([
                        name: "${env.JOB_NAME}",
                        classifier: "NONE",
                        collectionLogic: "AGGREGATE_LATEST_VERSION_CHILDREN"
                    ])

                    // create root project
                    httpRequest contentType: 'APPLICATION_JSON',
                        httpMode: 'PUT',
                        customHeaders: [
                            [name: 'X-Api-Key', value: env.DEPENDENCYTRACK_API_TOKEN, maskValue: true]
                        ],
                        requestBody: body,
                        url: "${DEPENDENCYTRACK_HOST}/api/v1/project",
                        validResponseCodes: '200:299,409' // 409: project already exist
                }

                dependencyTrackPublisher(
                    artifact: 'bom.xml',
                    projectName: env.JOB_NAME,
                    projectVersion: env.BUILD_NUMBER,
                    synchronous: false,
                    projectProperties: [
                        isLatest: true,
                        parentName: env.JOB_NAME,
                        tags: ['image']
                    ]
                )
            }
        }
    }

    post {
        always {
            discordSend result: currentBuild.currentResult,
                description: env.GIT_URL,
                link: env.BUILD_URL,
                title: JOB_NAME,
                webhookURL: DISCORD_WEBHOOK
            cleanWs()
        }
    }
}
