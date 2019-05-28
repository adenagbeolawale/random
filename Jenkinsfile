pipeline {

	agent { label 'master' }

	environment {
		WP_AWS_ACCESS_KEY_ID = credentials('aws_access_key_id')
    		WP_AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key') 
    		WP_DB_ADMIN = credentials('wordpress_db_admin')
    		WP_DB_PASSWORD = credentials('wordpress_db_password')
		WP_PATH_TO_PUBLIC_KEY = credentials('aws_key_file')
	}
	stages {
		stage('Terraform Plan') {
			steps {
				withEnv( ["PATH+TER=/usr/local/bin"] ) {
					withCredentials([file(credentialsId: 'WP_PATH_TO_PUBLIC_KEY', variable: 'my_public_key')]) {
						sh '''
							terraform init
							terraform plan \
							-var 'AWS_ACCESS_KEY_ID=${env.WP_AWS_ACCESS_KEY_ID}' \
							-var 'AWS_SECRET_ACCESS_KEY=${env.WP_AWS_SECRET_ACCESS_KEY}' \
							-var 'DB_ADMIN=${env.WP_DB_ADMIN}' \
							-var 'DB_PASSWORD=${env.WP_DB_PASSWORD}' \
							-var 'PATH_TO_PUBLIC_KEY=\$my_public_key' \
							-out wordpressplan
						'''
					}
				}
			}      
		}
	
		stage('Approve') {
			steps {
				script {
					def userInput = input(id: 'confirm', message: 'Apply Terraform?', parameters: [ [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Apply terraform', name: 'confirm'] ])
				}
			}
		}

		stage('Terraform Apply') {
			steps {
				sh '''
					terraform apply -input=false -auto-approve \
					-var "AWS_ACCESS_KEY_ID=${env.AWS_ACCESS_KEY_ID}" \
					-var "AWS_SECRET_ACCESS_KEY=${env.AWS_SECRET_ACCESS_KEY}" \
					-var "DB_ADMIN=${env.DB_ADMIN}" \
					-var "DB_PASSWORD=${env.DB_PASSWORD}" \
					-var "PATH_TO_PUBLIC_KEY=${env.PATH_TO_PUBLIC_KEY}" \
					wordpressplan
				'''
			}
		}
    
		stage('Archive Artifacts') {
			steps {
				archiveArtifacts artifacts: 'wordpressplan', fingerprint: true, onlyIfSuccessful: true
			}
		}
	}
}
