package student;

import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;
import javax.persistence.Persistence;

public class StudentMain {

    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) {
        
        Student student = new Student(1, "Boy", 3.25);
        persist(student);
        updateStudent(1, "Buy", 3.75);
        deleteStudent(1);
    }


    public static void persist(Object object) {
        EntityManagerFactory emf = Persistence.createEntityManagerFactory("Student");
        EntityManager em = emf.createEntityManager();
        em.getTransaction().begin();
        try {
            em.persist(object);
            em.getTransaction().commit();
        } catch (Exception e) {
            e.printStackTrace();
            em.getTransaction().rollback();
        } finally {
            em.close();
        }
    }

    public static void updateStudent(int id, String newName, double newGpa) {
        EntityManagerFactory emf = Persistence.createEntityManagerFactory("Student");
        EntityManager em = emf.createEntityManager();
        em.getTransaction().begin();
        try {
            Student student = em.find(Student.class, id);
            if (student != null) {
                student.setName(newName);
                student.setGpa(newGpa);
                em.getTransaction().commit();
            } else {
                System.out.println("ID :" + id + " not found.");
                em.getTransaction().rollback();
            }
        } catch (Exception e) {
            e.printStackTrace();
            em.getTransaction().rollback();
        } finally {
            em.close();
        }
    }

    public static void deleteStudent(int id) {
        EntityManagerFactory emf = Persistence.createEntityManagerFactory("Student");
        EntityManager em = emf.createEntityManager();
        em.getTransaction().begin();
        try {
            Student student = em.find(Student.class, id);
            if (student != null) {
                em.remove(student);
                em.getTransaction().commit();
            } else {
                System.out.println("ID :" + id + " not found.");
                em.getTransaction().rollback();
            }
        } catch (Exception e) {
            e.printStackTrace();
            em.getTransaction().rollback();
        } finally {
            em.close();
        }
    }

}