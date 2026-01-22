import os
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model


class Command(BaseCommand):
    help = "Creates a superuser if one doesn't exist"

    def handle(self, *args, **options):
        User = get_user_model()
        username = os.environ.get("DJANGO_SUPERUSER_USERNAME", "admin")
        email = os.environ.get("DJANGO_SUPERUSER_EMAIL", "admin@example.com")
        password = os.environ.get("DJANGO_SUPERUSER_PASSWORD", "admin")

        if not username or not password:
            self.stdout.write(
                self.style.WARNING("Superuser details not found in env vars. Skipping.")
            )
            return

        if User.objects.filter(username=username).exists():
            self.stdout.write(
                self.style.SUCCESS(f'Superuser "{username}" already exists.')
            )
        else:
            User.objects.create_superuser(username, email, password)
            self.stdout.write(
                self.style.SUCCESS(f'Successfully created superuser "{username}"')
            )
