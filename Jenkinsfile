pipeline {

	agent any

	environment {
		AWS_ACCESS_KEY_ID = credentials('aws_access_key_id')
    		AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key') 
    		DB_ADMIN = credentials('wordpress_db_admin')
    		DB_PASSWORD = credentials('wordpress_db_password')
		PATH_TO_PUBLIC_KEY = credentials(aws_key_file)
	}

	stages {

		stage('Checkout Source') {
			steps {
        		sh 'wget https://github.com/adenagbeolawale/wordpress-deploy/archive/master.zip'
        		sh 'unzip master.zip' 
      		}
    	}

    	stage('Terraform Plan') {
      		steps {
          		sh 'cd wordpress-deploy-master'
          		sh 'terraform init'
          		sh 'terraform plan -out wordpressplan'
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
          		sh 'terraform apply -input=false -auto-approve -var "AWS_ACCESS_KEY_ID=${env.AWS_ACCESS_KEY_ID}" -var "AWS_SECRET_ACCESS_KEY=${env.AWS_SECRET_ACCESS_KEY}" -var "DB_ADMIN=${env.DB_ADMIN}" -var "DB_PASSWORD=${env.DB_PASSWORD}" -var "PATH_TO_PUBLIC_KEY=${env.PATH_TO_PUBLIC_KEY}" wordpressplan'
			}
    	}
    
    	stage('Archive Artifacts') {
			steps {
				archiveArtifacts artifacts: 'wordpressplan', fingerprint: true, onlyIfSuccessful: true
			}
    	}
    	
    	stage('Cleanup') {
			steps {
				sh 'rm master.zip'
			}
    	}
	}
}
