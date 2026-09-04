from django.urls import path
from django.http import HttpResponse

def health_check(request):
    return HttpResponse("OK", status=200)

urlpatterns = [
    path('', health_check),
    path('up', health_check),
]
