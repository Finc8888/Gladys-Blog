node {
    checkout scm

    def blogImage = docker.build("gladys-blog:${env.BUILD_ID}", "./deploy/hugo")

    blogImage.inside {
        sh 'hugo'
    }
}
