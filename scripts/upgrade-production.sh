#!/bin/bash

docker pull kirpachov/lpda2-rails &&
	git pull &&
	docker compose down &&
	docker compose up --remove-orphans --detach --force-recreate &&
	docker compose run rails rails db:migrate &&
	docker compose logs -f
