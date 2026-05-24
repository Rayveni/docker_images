import click
from os import environ,path
import shutil

out_folder='/app/out'
@click.command()
@click.option('--count', default=1, help='Number of greetings.')
@click.option('--name', prompt='Your name', help='The person to greet.')
@click.option('--requirements', default=0, help='Export requirements.in')
def hello(count, name,requirements:int=0):
    """Приветствует ИМЯ (`name`), несколько (`count`) раз."""
    
    if requirements==1:
        shutil.copy('requirements.in', path.join(out_folder,"requirements.in"))
    else:
        click.echo(f"token {environ.get('hugging_token')}!")
        with open(path.join(out_folder,"example.txt"), "w") as file:
            file.write("Hello, World!\n") 
            
            
        for x in range(count):
            click.echo(f"Hello {name}!")
    

if __name__ == "__main__":
    hello()
    


